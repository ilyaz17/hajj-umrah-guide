import { createClient } from './supabase/server.js'

/**
 * Subscription tier limits configuration
 * Defines the maximum allowed resources for each subscription tier
 */
const TIER_LIMITS = {
  free: {
    maxGroups: 3,
    maxRitualLogsPerMonth: 100,
    features: {
      gpsTracking: false,
      offlineAudio: false,
      familyTracking: false,
      crowdDensity: false,
      aiAssistant: false
    }
  },
  lite: {
    maxGroups: 15,
    maxRitualLogsPerMonth: 2000,
    features: {
      gpsTracking: true,
      offlineAudio: true,
      familyTracking: false,
      crowdDensity: false,
      aiAssistant: false
    }
  },
  pro: {
    maxGroups: -1, // Unlimited
    maxRitualLogsPerMonth: -1, // Unlimited
    features: {
      gpsTracking: true,
      offlineAudio: true,
      familyTracking: true,
      crowdDensity: true,
      aiAssistant: true
    }
  }
}

/**
 * Gets the user's current usage statistics
 * 
 * @param {string} userId - The user's UUID
 * @returns {Promise<{ groupCount: number, ritualLogsThisMonth: number }>}
 */
async function getUserUsageStats(userId) {
  const supabase = await createClient()
  
  // Count active group profiles
  const { count: groupCount } = await supabase
    .from('group_profiles')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
  
  // Count ritual logs created in the current month
  const now = new Date()
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1)
  
  const { count: ritualLogsThisMonth } = await supabase
    .from('ritual_logs')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .gte('created_at', startOfMonth.toISOString())
  
  return {
    groupCount: groupCount || 0,
    ritualLogsThisMonth: ritualLogsThisMonth || 0
  }
}

/**
 * Checks if the user can perform a specific action based on their subscription tier
 * This is the application-level guard that works alongside database triggers
 * 
 * @param {string} userId - The user's UUID
 * @param {'CREATE_GROUP' | 'LOG_RITUAL' | 'ACCESS_FEATURE'} actionType - The action being attempted
 * @param {Object} options - Additional options for the check
 * @param {string} options.featureName - Required when actionType is 'ACCESS_FEATURE'
 * @returns {Promise<{ allowed: boolean, reason: string | null, currentUsage: number, limit: number }>}
 */
export async function checkTierLimits(userId, actionType, options = {}) {
  try {
    const supabase = await createClient()
    
    // Get user's profile with subscription tier
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('subscription_tier')
      .eq('user_id', userId)
      .single()
    
    if (profileError || !profile) {
      return {
        allowed: false,
        reason: 'User profile not found',
        currentUsage: 0,
        limit: 0
      }
    }
    
    const tier = profile.subscription_tier || 'free'
    const limits = TIER_LIMITS[tier]
    
    // Handle feature access checks
    if (actionType === 'ACCESS_FEATURE') {
      const { featureName } = options
      
      if (!featureName) {
        return {
          allowed: false,
          reason: 'Feature name required for ACCESS_FEATURE check',
          currentUsage: 0,
          limit: 0
        }
      }
      
      const hasAccess = limits.features[featureName] === true
      
      return {
        allowed: hasAccess,
        reason: hasAccess ? null : `Feature '${featureName}' requires ${tier === 'free' ? 'Lite or Pro' : 'Pro'} subscription`,
        currentUsage: 0,
        limit: 1
      }
    }
    
    // Get current usage
    const usage = await getUserUsageStats(userId)
    
    // Handle CREATE_GROUP action
    if (actionType === 'CREATE_GROUP') {
      const limit = limits.maxGroups
      const isUnlimited = limit === -1
      
      if (isUnlimited) {
        return {
          allowed: true,
          reason: null,
          currentUsage: usage.groupCount,
          limit: Infinity
        }
      }
      
      const allowed = usage.groupCount < limit
      
      return {
        allowed,
        reason: allowed 
          ? null 
          : `Free tier limited to ${limit} groups. Upgrade to Lite or Pro for more.`,
        currentUsage: usage.groupCount,
        limit
      }
    }
    
    // Handle LOG_RITUAL action
    if (actionType === 'LOG_RITUAL') {
      const limit = limits.maxRitualLogsPerMonth
      const isUnlimited = limit === -1
      
      if (isUnlimited) {
        return {
          allowed: true,
          reason: null,
          currentUsage: usage.ritualLogsThisMonth,
          limit: Infinity
        }
      }
      
      const allowed = usage.ritualLogsThisMonth < limit
      
      return {
        allowed,
        reason: allowed 
          ? null 
          : `${tier.toUpperCase()} tier limited to ${limit} ritual logs per month. Upgrade for unlimited.`,
        currentUsage: usage.ritualLogsThisMonth,
        limit
      }
    }
    
    // Unknown action type
    return {
      allowed: false,
      reason: `Unknown action type: ${actionType}`,
      currentUsage: 0,
      limit: 0
    }
    
  } catch (error) {
    console.error('Subscription guard error:', error)
    return {
      allowed: false,
      reason: 'Unable to verify subscription status',
      currentUsage: 0,
      limit: 0
    }
  }
}

/**
 * Gets detailed information about the user's subscription and usage
 * Useful for displaying upgrade prompts or usage dashboards
 * 
 * @param {string} userId - The user's UUID
 * @returns {Promise<{ tier: string, limits: Object, usage: Object, canUpgrade: boolean }>}
 */
export async function getSubscriptionDetails(userId) {
  try {
    const supabase = await createClient()
    
    const { data: profile } = await supabase
      .from('profiles')
      .select('subscription_tier')
      .eq('user_id', userId)
      .single()
    
    const tier = profile?.subscription_tier || 'free'
    const usage = await getUserUsageStats(userId)
    const limits = TIER_LIMITS[tier]
    
    return {
      tier,
      limits: {
        maxGroups: limits.maxGroups === -1 ? 'Unlimited' : limits.maxGroups,
        maxRitualLogsPerMonth: limits.maxRitualLogsPerMonth === -1 ? 'Unlimited' : limits.maxRitualLogsPerMonth,
        features: limits.features
      },
      usage,
      canUpgrade: tier !== 'pro'
    }
  } catch (error) {
    console.error('Error getting subscription details:', error)
    return null
  }
}

/**
 * Middleware helper to enforce tier-based access control
 * Use this in Server Actions before performing mutations
 * 
 * @example
 * const result = await enforceTierLimit(userId, 'CREATE_GROUP')
 * if (!result.allowed) {
 *   throw new Error(result.reason)
 * }
 * // Proceed with creation...
 * 
 * @param {string} userId 
 * @param {'CREATE_GROUP' | 'LOG_RITUAL' | 'ACCESS_FEATURE'} actionType 
 * @param {Object} options 
 * @throws {Error} If action is not allowed
 * @returns {Promise<Object>} The check result if allowed
 */
export async function enforceTierLimit(userId, actionType, options = {}) {
  const result = await checkTierLimits(userId, actionType, options)
  
  if (!result.allowed) {
    throw new Error(result.reason || 'Action not allowed based on subscription tier')
  }
  
  return result
}

export { TIER_LIMITS }

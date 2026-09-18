import { createClient } from './supabase/server.js';

/**
 * Subscription tier limits configuration
 * Defines the maximum allowed resources for each subscription tier
 */
const TIER_LIMITS = {
  FREE: {
    maxGroups: 3,
    maxRitualLogs: 100, // Total lifetime limit
  },
  LITE: {
    maxGroups: 15,
    maxRitualLogs: 2000, // Monthly limit
  },
  PRO: {
    maxGroups: 999999, // Effectively unlimited
    maxRitualLogs: 999999, // Effectively unlimited
  },
};

/**
 * Checks if a user can perform a specific action based on their subscription tier.
 * This function queries Supabase to get the user's current tier and usage counts,
 * then validates against the tier-specific limits.
 * 
 * @param {string} userId - The UUID of the authenticated user
 * @param {string} actionType - The type of action being performed ('CREATE_GROUP' or 'LOG_RITUAL')
 * @returns {Promise<{allowed: boolean, reason: string|null, currentUsage: number, limit: number}>}
 * 
 * @example
 * // In a Server Action before creating a group:
 * const result = await checkTierLimits(userId, 'CREATE_GROUP');
 * if (!result.allowed) {
 *   throw new Error(result.reason);
 * }
 * 
 * @example
 * // In a Server Action before logging a ritual:
 * const result = await checkTierLimits(userId, 'LOG_RITUAL');
 * if (!result.allowed) {
 *   return { error: result.reason };
 * }
 */
export async function checkTierLimits(userId, actionType) {
  const supabase = await createClient();

  try {
    // Get user's subscription tier from profiles table
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('subscription_tier')
      .eq('id', userId)
      .single();

    if (profileError || !profile) {
      return {
        allowed: false,
        reason: 'User profile not found. Please ensure you have completed registration.',
        currentUsage: 0,
        limit: 0,
      };
    }

    const tier = profile.subscription_tier || 'FREE';
    const limits = TIER_LIMITS[tier] || TIER_LIMITS.FREE;

    // Check CREATE_GROUP action
    if (actionType === 'CREATE_GROUP') {
      // Count active groups for this user
      const { data: groups, error: groupsError } = await supabase
        .from('group_profiles')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('is_active', true);

      if (groupsError) {
        console.error('Error fetching group count:', groupsError);
        return {
          allowed: false,
          reason: 'Failed to verify subscription limits. Please try again.',
          currentUsage: 0,
          limit: limits.maxGroups,
        };
      }

      const currentUsage = groups?.length || 0;

      if (currentUsage >= limits.maxGroups) {
        return {
          allowed: false,
          reason: `You've reached your subscription limit of ${limits.maxGroups} active groups. Upgrade to ${tier === 'FREE' ? 'LITE' : 'PRO'} for more groups.`,
          currentUsage,
          limit: limits.maxGroups,
        };
      }

      return {
        allowed: true,
        reason: null,
        currentUsage,
        limit: limits.maxGroups,
      };
    }

    // Check LOG_RITUAL action
    if (actionType === 'LOG_RITUAL') {
      let currentUsage = 0;

      if (tier === 'FREE') {
        // FREE tier: count total lifetime ritual logs
        const { data: logs, error: logsError } = await supabase
          .from('ritual_logs')
          .select('group_profiles(user_id)', { count: 'exact', head: true })
          .in(
            'group_profile_id',
            (await supabase.from('group_profiles').select('id').eq('user_id', userId)).data?.map(g => g.id) || []
          );

        if (logsError) {
          console.error('Error fetching ritual log count:', logsError);
          return {
            allowed: false,
            reason: 'Failed to verify subscription limits. Please try again.',
            currentUsage: 0,
            limit: limits.maxRitualLogs,
          };
        }

        currentUsage = logs?.length || 0;
      } else {
        // LITE/PRO tier: count monthly ritual logs
        const startOfMonth = new Date();
        startOfMonth.setDate(1);
        startOfMonth.setHours(0, 0, 0, 0);

        const userGroups = await supabase.from('group_profiles').select('id').eq('user_id', userId);
        const groupIds = userGroups.data?.map(g => g.id) || [];

        if (groupIds.length === 0) {
          return {
            allowed: true,
            reason: null,
            currentUsage: 0,
            limit: limits.maxRitualLogs,
          };
        }

        const { data: logs, error: logsError } = await supabase
          .from('ritual_logs')
          .select('id', { count: 'exact', head: true })
          .in('group_profile_id', groupIds)
          .gte('created_at', startOfMonth.toISOString());

        if (logsError) {
          console.error('Error fetching monthly ritual log count:', logsError);
          return {
            allowed: false,
            reason: 'Failed to verify subscription limits. Please try again.',
            currentUsage: 0,
            limit: limits.maxRitualLogs,
          };
        }

        currentUsage = logs?.length || 0;
      }

      if (currentUsage >= limits.maxRitualLogs) {
        const periodText = tier === 'FREE' ? 'total' : 'per month';
        return {
          allowed: false,
          reason: `You've reached your subscription limit of ${limits.maxRitualLogs} ritual logs (${periodText}). Upgrade to ${tier === 'LITE' ? 'PRO' : 'a higher tier'} for more logs.`,
          currentUsage,
          limit: limits.maxRitualLogs,
        };
      }

      return {
        allowed: true,
        reason: null,
        currentUsage,
        limit: limits.maxRitualLogs,
      };
    }

    // Unknown action type
    return {
      allowed: false,
      reason: `Unknown action type: ${actionType}`,
      currentUsage: 0,
      limit: 0,
    };
  } catch (error) {
    console.error('Unexpected error in checkTierLimits:', error);
    return {
      allowed: false,
      reason: 'An unexpected error occurred. Please try again.',
      currentUsage: 0,
      limit: 0,
    };
  }
}

/**
 * Gets detailed usage statistics for a user's subscription.
 * Useful for displaying usage dashboards or progress bars.
 * 
 * @param {string} userId - The UUID of the authenticated user
 * @returns {Promise<{tier: string, groups: {current: number, max: number}, ritualLogs: {current: number, max: number, period: string}}>}
 */
export async function getUserUsageStats(userId) {
  const supabase = await createClient();

  try {
    // Get user's tier
    const { data: profile } = await supabase
      .from('profiles')
      .select('subscription_tier')
      .eq('id', userId)
      .single();

    const tier = profile?.subscription_tier || 'FREE';
    const limits = TIER_LIMITS[tier] || TIER_LIMITS.FREE;

    // Get active groups count
    const { data: groups } = await supabase
      .from('group_profiles')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_active', true);

    // Get ritual logs count (depends on tier)
    let ritualLogsCurrent = 0;
    let period = 'lifetime';

    if (tier === 'FREE') {
      const userGroups = await supabase.from('group_profiles').select('id').eq('user_id', userId);
      const groupIds = userGroups.data?.map(g => g.id) || [];

      if (groupIds.length > 0) {
        const { data: logs } = await supabase
          .from('ritual_logs')
          .select('id', { count: 'exact', head: true })
          .in('group_profile_id', groupIds);

        ritualLogsCurrent = logs?.length || 0;
      }
    } else {
      period = 'monthly';
      const startOfMonth = new Date();
      startOfMonth.setDate(1);
      startOfMonth.setHours(0, 0, 0, 0);

      const userGroups = await supabase.from('group_profiles').select('id').eq('user_id', userId);
      const groupIds = userGroups.data?.map(g => g.id) || [];

      if (groupIds.length > 0) {
        const { data: logs } = await supabase
          .from('ritual_logs')
          .select('id', { count: 'exact', head: true })
          .in('group_profile_id', groupIds)
          .gte('created_at', startOfMonth.toISOString());

        ritualLogsCurrent = logs?.length || 0;
      }
    }

    return {
      tier,
      groups: {
        current: groups?.length || 0,
        max: limits.maxGroups,
      },
      ritualLogs: {
        current: ritualLogsCurrent,
        max: limits.maxRitualLogs,
        period,
      },
    };
  } catch (error) {
    console.error('Error fetching usage stats:', error);
    return {
      tier: 'FREE',
      groups: { current: 0, max: 3 },
      ritualLogs: { current: 0, max: 100, period: 'lifetime' },
    };
  }
}

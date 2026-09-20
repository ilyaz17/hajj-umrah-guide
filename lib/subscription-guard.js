import { createClient } from '@/lib/supabase/server'

export const TIER_RANK = { free: 0, lite: 1, pro: 2 }
export const FEATURES = { gpsTracking: 'lite', offlineAudio: 'lite', itinerary: 'lite', familyTracking: 'pro', crowdDensity: 'pro', aiAssistant: 'pro' }

export async function getCurrentTier() {
  const supabase = await createClient(); const { user } = await supabase.auth.getUser()
  if (!user) return 'free'
  const { data } = await supabase.from('profiles').select('subscription_tier').eq('user_id', user.id).maybeSingle()
  return data?.subscription_tier || 'free'
}

export function canAccess(tier, feature) { return TIER_RANK[tier] >= TIER_RANK[FEATURES[feature] || 'free'] }
export async function requireFeature(feature) { const tier = await getCurrentTier(); return { tier, allowed: canAccess(tier, feature) } }

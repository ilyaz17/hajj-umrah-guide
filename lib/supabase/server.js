import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

/**
 * Creates a Supabase server client for use in Server Components and Server Actions.
 * This uses the cookie-based authentication pattern from @supabase/ssr.
 *
 * The server client allows you to:
 * - Query the database with RLS policies applied based on the authenticated user
 * - Access the current user's session
 * - Perform server-side operations securely without exposing keys to the client
 *
 * @returns {Promise<ReturnType<typeof createServerClient>>} Supabase server client instance
 */
export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // If we're here, it means we're trying to set cookies from a Server Component.
            // This is expected behavior when using createServerClient in RSCs.
            // The cookies will be set properly when called from Server Actions or Route Handlers.
          }
        }
      }
    }
  )
}

/**
 * Gets the currently authenticated user from the session.
 * Returns null if not authenticated.
 *
 * @returns {Promise<{ user: any | null, error: any | null }>} User object or null
 */
export async function getUser() {
  try {
    const supabase = await createClient()
    const { data: { user }, error } = await supabase.auth.getUser()

    if (error || !user) {
      return { user: null, error: error || new Error('No user found') }
    }

    return { user, error: null }
  } catch (error) {
    return { user: null, error }
  }
}

/**
 * Gets the user's profile with subscription tier information.
 * Returns null if not authenticated or profile doesn't exist.
 *
 * @returns {Promise<{ profile: any | null, error: any | null }>} Profile object or null
 */
export async function getUserProfile() {
  try {
    const supabase = await createClient()
    const { user, error: authError } = await getUser()

    if (authError || !user) {
      return { profile: null, error: authError || new Error('Not authenticated') }
    }

    const { data: profile, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('user_id', user.id)
      .single()

    if (error || !profile) {
      return { profile: null, error: error || new Error('Profile not found') }
    }

    return { profile, error: null }
  } catch (error) {
    return { profile: null, error }
  }
}

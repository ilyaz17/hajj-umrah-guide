import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

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
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // If we're here, it means we're trying to set cookies from a Server Component.
            // This is expected behavior when using createServerClient in RSCs.
            // The cookies will be set properly when called from Server Actions or Route Handlers.
          }
        },
      },
    }
  );
}

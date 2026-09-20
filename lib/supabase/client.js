'use client'

import { createBrowserClient } from '@supabase/ssr'

let client
export function createClient() {
  if (client) return client
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
  client = createBrowserClient(process.env.NEXT_PUBLIC_SUPABASE_URL, key)
  return client
}

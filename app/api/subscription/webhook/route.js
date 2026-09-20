import { NextResponse } from 'next/server'

// Payment providers can call this endpoint later. Validate signatures before
// enabling production updates; this stub intentionally accepts a mock payload.
export async function POST(request) {
  const body = await request.json().catch(() => null)
  if (!body?.user_id || !['free', 'lite', 'pro'].includes(body?.subscription_tier)) return NextResponse.json({ error: 'user_id and valid subscription_tier are required' }, { status: 400 })
  return NextResponse.json({ received: true, message: 'Mock webhook received. Add provider signature verification and a service-role update here.' })
}

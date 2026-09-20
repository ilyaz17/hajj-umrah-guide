# Hajj & Umrah Guide

A mobile-first, location-aware pilgrimage companion built with Next.js App Router, Supabase, Tailwind CSS, and JavaScript.

## Quick start

```bash
npm install
cp .env.local.example .env.local
npm run dev
```

Apply `supabase/migrations/001_init_schema.sql` in the Supabase SQL editor, then open `http://localhost:3000`.

### Environment variables

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-publishable-or-anon-key
# Legacy name is also supported:
# NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=server-only-key
```

`SUPABASE_SERVICE_ROLE_KEY` is only needed for trusted server/webhook work and must never be exposed to the browser. Enable Email and Magic Link providers in Supabase Authentication. The SQL migration creates profiles automatically when users sign up, RLS policies, seed rituals, and tier helper functions.

## Product structure

- `/` — dashboard with location-aware ritual guidance, counters, and tier status
- `/auth` — email/password and magic-link sign in
- `/pricing` — Free, Lite, and Pro plan comparison with a mock upgrade action
- `hooks/useGeoLocation.js` — GPS tracking and geofence helpers
- `lib/subscription-guard.js` — server-side feature gates
- `app/api/subscription/webhook/route.js` — payment-provider webhook stub

This project intentionally uses JavaScript and JSX only. GPS and family tracking require explicit user permission and should be treated as sensitive data.

# Hajj & Umrah Guide SaaS

A production-ready location-aware pilgrimage companion web application built with Next.js 14+, Supabase, and Tailwind CSS.

## Features

### Multi-Tier Subscription System
- **Free**: Basic ritual guides, manual counters, standard dua library
- **Lite ($9/mo)**: GPS tracking, offline audio guides, personalized itinerary
- **Pro ($29/mo)**: Family tracking, crowd density alerts, AI assistant, priority support

### Core Functionality
- Real-time GPS-based ritual detection and guidance
- Interactive Tawaf (7 circuits) and Sa'i counters with haptic feedback
- Geofencing around holy sites (Masjid al-Haram, Mina, Arafat, Muzdalifah, Jamarat)
- Location-aware duas and step-by-step ritual instructions
- Offline-ready content for areas with poor connectivity
- Group/family member tracking (Pro tier)

## Tech Stack

- **Framework**: Next.js 14+ (App Router)
- **Language**: JavaScript (ES6+/JSX) - No TypeScript
- **Backend/Database/Auth**: Supabase
- **Styling**: Tailwind CSS with Emerald/Islamic Green theme
- **Icons**: lucide-react
- **Geolocation**: HTML5 Geolocation API

## Project Structure

```
/workspace
├── app/
│   └── pricing/
│       └── page.jsx          # Pricing page (Server Component)
├── components/
│   ├── pricing-cards.jsx     # Pricing cards component (Client Component)
│   └── ui/                   # shadcn/ui components
├── hooks/
│   └── useGeoLocation.js     # Geolocation hook with utilities
├── lib/
│   ├── supabase/
│   │   └── server.js         # Supabase server client setup
│   └── subscription-guard.js # Tier-based access control
├── supabase/
│   └── migrations/
│       └── 001_init_schema.sql # Database schema & seed data
├── .env.local.example        # Environment variables template
└── README.md
```

## Getting Started

### 1. Clone and Install Dependencies

```bash
cd /workspace
npm install
npm install @supabase/supabase-js @supabase/ssr lucide-react
```

### 2. Set Up Environment Variables

Copy the example environment file and fill in your Supabase credentials:

```bash
cp .env.local.example .env.local
```

Edit `.env.local` with your values from [Supabase Dashboard](https://app.supabase.com):

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 3. Run Database Migrations

Apply the database schema to your Supabase project:

1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy the contents of `supabase/migrations/001_init_schema.sql`
4. Paste and run the SQL script

Or use the Supabase CLI:

```bash
npx supabase db push
```

### 4. Start Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to see the application.

## Database Schema Overview

### Tables

- **profiles**: User profiles with subscription tier and pilgrimage status
- **rituals**: Location-based ritual guidance with geofencing coordinates
- **user_progress**: Tracks individual user progress through rituals
- **group_members**: Pro tier feature for family member tracking
- **subscription_webhooks**: Mock webhook endpoint for payment processing

### Key Features

- Row-Level Security (RLS) enabled on all tables
- Automatic updated_at triggers
- Helper functions for tier checking (`get_user_tier()`, `has_tier_access()`)
- Seed data for major holy sites with coordinates

## Subscription Guard System

The application implements dual-layer enforcement:

### 1. Application Layer (`lib/subscription-guard.js`)

```javascript
import { checkTierLimits } from '@/lib/subscription-guard'

// In Server Actions before mutations
const result = await checkTierLimits(userId, 'CREATE_GROUP')
if (!result.allowed) {
  throw new Error(result.reason)
}
```

### 2. Database Layer (PostgreSQL Triggers)

Database triggers automatically enforce limits on INSERT operations, providing a safety net even if application-level checks are bypassed.

## Geolocation Features

The `useGeoLocation` hook provides:

- Real-time GPS tracking with configurable accuracy
- Permission handling and error states
- Haversine distance calculations
- Geofencing utilities (`isWithinRadius`)
- Bearing and cardinal direction helpers

```javascript
import { useGeoLocation, isWithinRadius } from '@/hooks/useGeoLocation'

function RitualTracker() {
  const { location, loading, error } = useGeoLocation({
    enableHighAccuracy: true,
    watch: true
  })
  
  // Check if user is at Kaaba
  const isAtKaaba = isWithinRadius(location, {
    latitude: 21.422487,
    longitude: 39.826206
  }, 50) // 50 meters radius
}
```

## Color Palette

- **Primary Green**: `#0f5132` / `#15803d` (emerald-800 / emerald-700)
- **Accent Mint**: `#86efac` (green-300)
- **Gold/Sand**: `#d97706` (amber-600)
- **Background**: `#ffffff`, `#f8fafc`, `#f0fdf4`
- **Text**: High-contrast slate/emerald tones

## Payment Integration (Stub)

The current implementation includes a mock webhook endpoint (`subscription_webhooks` table). To integrate real payments:

1. Replace the stub function `process_subscription_webhook()` with actual Stripe/PayPal logic
2. Set up Supabase Edge Functions for secure webhook handling
3. Update the `handleSelectPlan` function in `pricing-cards.jsx` to redirect to checkout

## License

MIT

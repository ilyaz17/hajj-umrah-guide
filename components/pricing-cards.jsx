'use client'

import { Check, X } from 'lucide-react'
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'

const plans = [
  {
    name: 'Free',
    price: '$0',
    period: '/month',
    description: 'Essential guidance for your pilgrimage',
    tier: 'free',
    features: [
      { text: 'Basic step-by-step ritual guides', included: true },
      { text: 'Tawaf & Sa\'i counters (manual)', included: true },
      { text: 'Standard Dua library', included: true },
      { text: 'Basic maps of holy sites', included: true },
      { text: 'GPS-based ritual tracking', included: false },
      { text: 'Offline audio guides', included: false },
      { text: 'Family member tracking', included: false },
      { text: 'Crowd density alerts', included: false },
      { text: 'AI ritual assistant', included: false }
    ],
    cta: 'Get Started',
    popular: false
  },
  {
    name: 'Lite',
    price: '$9',
    period: '/month',
    description: 'Enhanced experience with GPS tracking',
    tier: 'lite',
    features: [
      { text: 'Basic step-by-step ritual guides', included: true },
      { text: 'Tawaf & Sa\'i counters (manual)', included: true },
      { text: 'Standard Dua library', included: true },
      { text: 'Basic maps of holy sites', included: true },
      { text: 'GPS-based ritual tracking', included: true },
      { text: 'Offline audio guides', included: true },
      { text: 'Personalized itinerary', included: true },
      { text: 'Family member tracking', included: false },
      { text: 'Crowd density alerts', included: false },
      { text: 'AI ritual assistant', included: false }
    ],
    cta: 'Upgrade to Lite',
    popular: false
  },
  {
    name: 'Pro',
    price: '$29',
    period: '/month',
    description: 'Complete pilgrimage companion with premium features',
    tier: 'pro',
    features: [
      { text: 'Basic step-by-step ritual guides', included: true },
      { text: 'Tawaf & Sa\'i counters (manual)', included: true },
      { text: 'Standard Dua library', included: true },
      { text: 'Basic maps of holy sites', included: true },
      { text: 'GPS-based ritual tracking', included: true },
      { text: 'Offline audio guides', included: true },
      { text: 'Personalized itinerary', included: true },
      { text: 'Family member tracking (Group Hub)', included: true },
      { text: 'Crowd density alerts', included: true },
      { text: 'AI ritual assistant', included: true },
      { text: 'Priority support', included: true }
    ],
    cta: 'Upgrade to Pro',
    popular: true
  }
]

export function PricingCards() {
  const handleSelectPlan = (tier) => {
    // TODO: Integrate with payment gateway
    console.log('Selected plan:', tier)
  }

  return (
    <div className="grid gap-8 lg:grid-cols-3">
      {plans.map((plan) => (
        <Card
          key={plan.tier}
          className={`relative flex flex-col ${
            plan.popular
              ? 'border-emerald-600 shadow-lg scale-105'
              : 'border-slate-200'
          }`}
        >
          {plan.popular && (
            <Badge
              variant="default"
              className="absolute -top-3 left-1/2 -translate-x-1/2 bg-emerald-600 hover:bg-emerald-700"
            >
              Most Popular
            </Badge>
          )}

          <CardHeader className="text-center pb-2">
            <CardTitle className="text-2xl font-bold text-slate-900">
              {plan.name}
            </CardTitle>
            <div className="mt-4 flex items-baseline justify-center gap-1">
              <span className="text-5xl font-bold text-emerald-700">
                {plan.price}
              </span>
              <span className="text-slate-500">{plan.period}</span>
            </div>
            <p className="mt-2 text-sm text-slate-600">{plan.description}</p>
          </CardHeader>

          <CardContent className="flex-1 pt-6">
            <ul className="space-y-3">
              {plan.features.map((feature, index) => (
                <li key={index} className="flex items-start gap-3">
                  {feature.included ? (
                    <Check className="h-5 w-5 text-emerald-600 shrink-0 mt-0.5" />
                  ) : (
                    <X className="h-5 w-5 text-slate-300 shrink-0 mt-0.5" />
                  )}
                  <span
                    className={`text-sm ${
                      feature.included ? 'text-slate-700' : 'text-slate-400'
                    }`}
                  >
                    {feature.text}
                  </span>
                </li>
              ))}
            </ul>
          </CardContent>

          <CardFooter className="pt-6">
            <Button
              className={`w-full ${
                plan.popular
                  ? 'bg-emerald-600 hover:bg-emerald-700 text-white'
                  : 'bg-slate-900 hover:bg-slate-800 text-white'
              }`}
              size="lg"
              onClick={() => handleSelectPlan(plan.tier)}
            >
              {plan.cta}
            </Button>
          </CardFooter>
        </Card>
      ))}
    </div>
  )
}

import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';

/**
 * Pricing cards component displaying the three subscription tiers.
 * This is a Client Component to enable interactive elements like hover states and button clicks.
 */

const plans = [
  {
    name: 'FREE',
    price: '$0',
    period: '/mo',
    description: 'Perfect for individual pilgrims tracking their personal journey',
    features: [
      'Max 3 active group profiles',
      '100 total logged ritual updates',
      'Access to public guides',
      'Basic maps navigation',
      'Standard support',
    ],
    limitations: [
      'No SOS broadcasting',
      'No real-time family syncing',
      'No historical routes',
    ],
    ctaText: 'Get Started Free',
    highlighted: false,
    borderColor: 'border-gray-200',
  },
  {
    name: 'LITE',
    price: '$9',
    period: '/mo',
    description: 'Ideal for families managing small groups during Hajj/Umrah',
    features: [
      'Max 15 active group profiles',
      '2,000 logged ritual milestones/month',
      'Real-time family syncing',
      'Historical routes tracking',
      'Offline guides access',
      'Priority email support',
    ],
    limitations: [
      'No crowd density analytics',
      'No prioritized SOS dashboard',
    ],
    ctaText: 'Start Lite Trial',
    highlighted: false,
    borderColor: 'border-emerald-500',
  },
  {
    name: 'PRO',
    price: '$29',
    period: '/mo',
    description: 'Complete solution for group leaders and travel agencies',
    features: [
      'Unlimited group profiles',
      'Unlimited historical tracking',
      'Unlimited ritual counters',
      'Prioritized SOS dashboard',
      'Crowd density analytics',
      'Family hub management',
      '24/7 priority support',
      'API access for integrations',
    ],
    limitations: [],
    ctaText: 'Go Pro Today',
    highlighted: true,
    borderColor: 'border-amber-500',
    badge: 'Most Popular',
  },
];

export function PricingCards() {
  return (
    <div className="grid grid-cols-1 gap-8 lg:grid-cols-3 lg:gap-12">
      {plans.map((plan) => (
        <Card
          key={plan.name}
          className={`relative flex h-full flex-col ${
            plan.highlighted
              ? `${plan.borderColor} border-2 shadow-lg`
              : `${plan.borderColor} border`
          } transition-all duration-300 hover:shadow-xl`}
        >
          {plan.badge && (
            <Badge
              variant="default"
              className="absolute -top-3 left-1/2 -translate-x-1/2 bg-amber-500 px-4 py-1 text-sm font-semibold"
            >
              {plan.badge}
            </Badge>
          )}

          <CardHeader className="pb-4">
            <CardTitle className="flex flex-col items-center text-center">
              <span className="text-3xl font-bold">{plan.name}</span>
              <div className="mt-4 flex items-baseline justify-center">
                <span className="text-5xl font-extrabold">{plan.price}</span>
                <span className="ml-1 text-xl text-muted-foreground">
                  {plan.period}
                </span>
              </div>
            </CardTitle>
            <p className="mt-4 text-sm text-muted-foreground">
              {plan.description}
            </p>
          </CardHeader>

          <CardContent className="flex flex-1 flex-col">
            <ul className="mb-6 space-y-3 text-sm">
              {plan.features.map((feature, index) => (
                <li key={index} className="flex items-start">
                  <svg
                    className="mr-2 h-5 w-5 flex-shrink-0 text-green-500"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  <span>{feature}</span>
                </li>
              ))}
              {plan.limitations.map((limitation, index) => (
                <li
                  key={index}
                  className="flex items-start text-muted-foreground"
                >
                  <svg
                    className="mr-2 h-5 w-5 flex-shrink-0 text-gray-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M6 18L18 6M6 6l12 12"
                    />
                  </svg>
                  <span>{limitation}</span>
                </li>
              ))}
            </ul>

            <Button
              className={`mt-auto w-full ${
                plan.highlighted
                  ? 'bg-amber-500 hover:bg-amber-600'
                  : plan.name === 'LITE'
                    ? 'bg-emerald-600 hover:bg-emerald-700'
                    : ''
              }`}
              variant={plan.highlighted || plan.name === 'LITE' ? 'default' : 'outline'}
              size="lg"
            >
              {plan.ctaText}
            </Button>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}

import { PricingCards } from '@/components/pricing-cards';

/**
 * Pricing page - Server Component
 * Displays subscription tiers with feature comparison for the Hajj/Umrah tracking platform.
 * 
 * This is a Server Component by default (no 'use client' directive) since it only
 * renders static content and doesn't require interactivity at the page level.
 * The interactive elements are handled by the child PricingCards component.
 */

export const metadata = {
  title: 'Pricing | Hajj/Umrah Group Tracker',
  description: 'Choose the perfect plan for your Hajj or Umrah journey. Compare FREE, LITE, and PRO subscription tiers.',
};

export default function PricingPage() {
  return (
    <div className="container mx-auto px-4 py-16">
      {/* Header Section */}
      <div className="mx-auto mb-16 max-w-3xl text-center">
        <h1 className="mb-4 text-4xl font-extrabold tracking-tight lg:text-5xl">
          Choose Your Perfect Plan
        </h1>
        <p className="text-lg text-muted-foreground">
          Whether you&apos;re traveling alone or leading a group, we have a plan that fits your needs.
          All plans include core features with tier-based limits on groups and ritual logs.
        </p>
      </div>

      {/* Pricing Cards Grid */}
      <PricingCards />

      {/* FAQ Section */}
      <div className="mx-auto mt-20 max-w-4xl">
        <h2 className="mb-8 text-center text-3xl font-bold">
          Frequently Asked Questions
        </h2>
        <div className="space-y-6">
          <div className="rounded-lg border bg-card p-6 shadow-sm">
            <h3 className="mb-2 text-lg font-semibold">
              Can I change my plan later?
            </h3>
            <p className="text-muted-foreground">
              Yes! You can upgrade or downgrade your subscription at any time. Changes take effect immediately,
              and we&apos;ll prorate any differences in billing.
            </p>
          </div>

          <div className="rounded-lg border bg-card p-6 shadow-sm">
            <h3 className="mb-2 text-lg font-semibold">
              What happens if I exceed my tier limits?
            </h3>
            <p className="text-muted-foreground">
              Our system enforces limits both at the application level and database level.
              If you reach your limit, you&apos;ll be prompted to upgrade before creating additional groups
              or logging more rituals. Your existing data remains accessible.
            </p>
          </div>

          <div className="rounded-lg border bg-card p-6 shadow-sm">
            <h3 className="mb-2 text-lg font-semibold">
              Is there a free trial for paid plans?
            </h3>
            <p className="text-muted-foreground">
              We offer a 7-day free trial for both LITE and PRO plans. No credit card required to start.
              Cancel anytime during the trial period without being charged.
            </p>
          </div>

          <div className="rounded-lg border bg-card p-6 shadow-sm">
            <h3 className="mb-2 text-lg font-semibold">
              What payment methods do you accept?
            </h3>
            <p className="text-muted-foreground">
              We accept all major credit cards (Visa, MasterCard, American Express), PayPal,
              and Apple Pay. All transactions are secured with industry-standard encryption.
            </p>
          </div>
        </div>
      </div>

      {/* CTA Section */}
      <div className="mx-auto mt-20 max-w-3xl text-center">
        <div className="rounded-2xl bg-gradient-to-r from-emerald-500 to-teal-600 p-8 text-white shadow-xl">
          <h2 className="mb-4 text-3xl font-bold">
            Ready to Start Your Journey?
          </h2>
          <p className="mb-6 text-lg opacity-90">
            Join thousands of pilgrims who trust our platform for their Hajj and Umrah experiences.
          </p>
          <div className="flex flex-col gap-4 sm:flex-row sm:justify-center">
            <button className="rounded-lg bg-white px-8 py-3 font-semibold text-emerald-600 transition-colors hover:bg-gray-100">
              Create Free Account
            </button>
            <button className="rounded-lg border-2 border-white px-8 py-3 font-semibold transition-colors hover:bg-white/10">
              Contact Sales
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

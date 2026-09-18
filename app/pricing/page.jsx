import { Suspense } from 'react'
import { PricingCards } from '@/components/pricing-cards'
import { Card, CardContent } from '@/components/ui/card'
import { HelpCircle, Shield, Headphones } from 'lucide-react'

export const metadata = {
  title: 'Pricing Plans - Hajj & Umrah Guide',
  description: 'Choose the perfect plan for your pilgrimage journey'
}

const faqs = [
  {
    question: 'Can I upgrade or downgrade my plan anytime?',
    answer: 'Yes, you can change your subscription tier at any time. Changes take effect immediately.'
  },
  {
    question: 'Is there a free trial for paid plans?',
    answer: 'We offer a 7-day free trial for both Lite and Pro plans. No credit card required to start.'
  },
  {
    question: 'What happens if I exceed my tier limits?',
    answer: 'You will be notified when approaching your limits. Upgrade to continue using premium features.'
  },
  {
    question: 'Do you offer group or family discounts?',
    answer: 'Contact our support team for custom group pricing for families traveling together.'
  }
]

function FAQSection() {
  return (
    <section className="mt-24 max-w-4xl mx-auto">
      <div className="text-center mb-12">
        <h2 className="text-3xl font-bold text-slate-900">
          Frequently Asked Questions
        </h2>
        <p className="mt-4 text-lg text-slate-600">
          Everything you need to know about our subscription plans
        </p>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {faqs.map((faq, index) => (
          <Card key={index} className="border-slate-200 bg-white">
            <CardContent className="pt-6">
              <div className="flex items-start gap-4">
                <HelpCircle className="h-6 w-6 text-emerald-600 shrink-0 mt-1" />
                <div>
                  <h3 className="font-semibold text-slate-900 mb-2">
                    {faq.question}
                  </h3>
                  <p className="text-slate-600">{faq.answer}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </section>
  )
}

function FeatureHighlights() {
  const highlights = [
    {
      icon: Shield,
      title: 'Secure & Private',
      description: 'Your location data is encrypted and never shared with third parties'
    },
    {
      icon: Headphones,
      title: '24/7 Support',
      description: 'Our team is available around the clock during Hajj and Umrah seasons'
    },
    {
      icon: HelpCircle,
      title: 'Offline Ready',
      description: 'Access guides and duas even without internet connection (Lite & Pro)'
    }
  ]

  return (
    <section className="mt-16 grid gap-8 md:grid-cols-3">
      {highlights.map((item, index) => (
        <Card key={index} className="border-slate-200 bg-emerald-50/50">
          <CardContent className="pt-6 text-center">
            <item.icon className="h-12 w-12 text-emerald-600 mx-auto mb-4" />
            <h3 className="font-semibold text-slate-900 mb-2">{item.title}</h3>
            <p className="text-sm text-slate-600">{item.description}</p>
          </CardContent>
        </Card>
      ))}
    </section>
  )
}

export default function PricingPage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-emerald-50 to-white">
      {/* Header */}
      <header className="py-16 text-center">
        <div className="container mx-auto px-4">
          <h1 className="text-4xl md:text-5xl font-bold text-slate-900 mb-4">
            Choose Your Pilgrimage Companion
          </h1>
          <p className="text-xl text-slate-600 max-w-2xl mx-auto">
            From basic guidance to complete family tracking, find the perfect plan 
            for your sacred journey
          </p>
        </div>
      </header>

      {/* Pricing Cards */}
      <main className="container mx-auto px-4 pb-24">
        <Suspense fallback={
          <div className="grid gap-8 lg:grid-cols-3">
            {[1, 2, 3].map((i) => (
              <Card key={i} className="h-96 animate-pulse bg-slate-100" />
            ))}
          </div>
        }>
          <PricingCards />
        </Suspense>

        <FeatureHighlights />
        <FAQSection />

        {/* CTA Section */}
        <section className="mt-24 text-center">
          <Card className="bg-emerald-600 border-emerald-600 max-w-2xl mx-auto">
            <CardContent className="py-12">
              <h2 className="text-3xl font-bold text-white mb-4">
                Ready to Start Your Journey?
              </h2>
              <p className="text-emerald-100 mb-8 max-w-md mx-auto">
                Join thousands of pilgrims who trust our guide for their 
                Hajj and Umrah experience
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <button className="px-8 py-3 bg-white text-emerald-600 font-semibold rounded-lg hover:bg-emerald-50 transition-colors">
                  Create Free Account
                </button>
                <button className="px-8 py-3 bg-emerald-700 text-white font-semibold rounded-lg hover:bg-emerald-800 transition-colors">
                  Contact Sales
                </button>
              </div>
            </CardContent>
          </Card>
        </section>
      </main>
    </div>
  )
}

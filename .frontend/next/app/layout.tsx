import type { Metadata, Viewport } from 'next';
import { Inter, Poppins } from 'next/font/google';
import './globals.css';
import { Providers } from '@/components/providers';

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
});

const poppins = Poppins({
  subsets: ['latin'],
  weight: ['300', '400', '500', '600', '700'],
  variable: '--font-poppins',
  display: 'swap',
});

export const metadata: Metadata = {
  title: {
    default: 'InfiniR - Infinite Reality Platform',
    template: '%s | InfiniR'
  },
  description: 'InfiniR is an AI-powered infinite reality platform that transforms how businesses operate through advanced automation, intelligent analytics, and seamless multi-platform experiences.',
  keywords: [
    'InfiniR',
    'AI platform',
    'infinite reality',
    'business automation',
    'analytics',
    'multi-platform',
    'enterprise software',
    'digital transformation'
  ],
  authors: [{ name: 'InfiniR Team' }],
  creator: 'InfiniR',
  publisher: 'InfiniR',
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  metadataBase: new URL('https://infinir.ai'),
  alternates: {
    canonical: '/',
    languages: {
      'en-US': '/en-US',
      'pl-PL': '/pl-PL',
    },
  },
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://infinir.ai',
    siteName: 'InfiniR',
    title: 'InfiniR - Infinite Reality Platform',
    description: 'AI-powered infinite reality platform for modern businesses',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'InfiniR - Infinite Reality Platform',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'InfiniR - Infinite Reality Platform',
    description: 'AI-powered infinite reality platform for modern businesses',
    images: ['/twitter-image.png'],
    creator: '@infinir_ai',
    site: '@infinir_ai',
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  verification: {
    google: 'your-google-verification-code',
    yandex: 'your-yandex-verification-code',
    yahoo: 'your-yahoo-verification-code',
  },
  category: 'technology',
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#000000' },
  ],
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${inter.variable} ${poppins.variable}`}>
      <head>
        <link rel="icon" href="/favicon.ico" sizes="any" />
        <link rel="icon" href="/favicon.svg" type="image/svg+xml" />
        <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
        <link rel="manifest" href="/manifest.json" />

        {/* Preconnect to external domains */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />

        {/* DNS prefetch for performance */}
        <link rel="dns-prefetch" href="https://www.google-analytics.com" />
        <link rel="dns-prefetch" href="https://www.googletagmanager.com" />

        {/* Structured Data */}
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              '@context': 'https://schema.org',
              '@type': 'Organization',
              name: 'InfiniR',
              url: 'https://infinir.ai',
              logo: 'https://infinir.ai/logo.png',
              description: 'AI-powered infinite reality platform for modern businesses',
              sameAs: [
                'https://twitter.com/infinir_ai',
                'https://linkedin.com/company/infinir',
                'https://github.com/infinir'
              ],
              contactPoint: {
                '@type': 'ContactPoint',
                telephone: '+1-555-0123',
                contactType: 'customer service',
                availableLanguage: ['English', 'Polish']
              }
            })
          }}
        />
      </head>
      <body className={`${inter.className} antialiased`}>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}

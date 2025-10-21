/**
 * InfiniR Next.js App Structure
 * SEO-optimized app exports for rice-mono projects
 */

// Layout exports
export { default as RootLayout } from './layout';
export { default as HomePage } from './page';

// Metadata utilities
export type { Metadata, Viewport } from 'next';

// SEO utilities
export const generateMetadata = (title: string, description?: string): Metadata => ({
  title,
  description: description || 'InfiniR - Infinite Reality Platform',
  openGraph: {
    title,
    description,
    type: 'website',
    siteName: 'InfiniR',
  },
  twitter: {
    card: 'summary_large_image',
    title,
    description,
  },
});

// App configuration
export const appConfig = {
  name: 'InfiniR',
  description: 'AI-powered infinite reality platform for modern businesses',
  url: 'https://infinir.ai',
  ogImage: '/og-image.png',
  twitterHandle: '@infinir_ai',
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
} as const;

// Font configurations
export const fontConfig = {
  inter: {
    variable: '--font-inter',
    display: 'swap',
  },
  poppins: {
    variable: '--font-poppins',
    display: 'swap',
    weights: ['300', '400', '500', '600', '700'],
  },
} as const;

// Default metadata for pages
export const defaultMetadata: Metadata = {
  title: {
    default: 'InfiniR - Infinite Reality Platform',
    template: '%s | InfiniR'
  },
  description: 'InfiniR is an AI-powered infinite reality platform that transforms how businesses operate through advanced automation, intelligent analytics, and seamless multi-platform experiences.',
  metadataBase: new URL('https://infinir.ai'),
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://infinir.ai',
    siteName: 'InfiniR',
    title: 'InfiniR - Infinite Reality Platform',
    description: 'AI-powered infinite reality platform for modern businesses',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'InfiniR - Infinite Reality Platform',
    description: 'AI-powered infinite reality platform for modern businesses',
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
};

// Viewport configuration
export const defaultViewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#000000' },
  ],
};

// Structured data generator
export const generateStructuredData = (type: 'Organization' | 'WebSite' | 'WebPage', data: any) => {
  const baseData = {
    '@context': 'https://schema.org',
    '@type': type,
    ...data,
  };

  return JSON.stringify(baseData);
};

// Default organization structured data
export const organizationStructuredData = generateStructuredData('Organization', {
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
});

// Performance optimization utilities
export const performanceConfig = {
  preconnect: [
    'https://fonts.googleapis.com',
    'https://fonts.gstatic.com',
  ],
  dnsPrefetch: [
    'https://www.google-analytics.com',
    'https://www.googletagmanager.com',
  ],
} as const;

// Export all app utilities
export * from './layout';
export * from './page';

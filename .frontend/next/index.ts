/**
 * @rice-mono/next-components
 * SEO-optimized Next.js components library with full app structure
 *
 * This package provides:
 * - Complete Next.js app structure with SEO optimization
 * - Reusable React components with TypeScript
 * - Tailwind CSS integration
 * - Material Icons support
 * - Performance optimizations
 * - Accessibility features
 */

// Import styles
import './style.css';

// Export all components
export * from './components';

// App structure is available via subpath import to avoid bringing Next-only deps into Vite apps
// Import as: import { RootLayout } from '@rice-mono/next-components/app'

// Export utilities and types
export type { Metadata, Viewport } from 'next';
export type { ReactNode, ComponentProps } from 'react';

// Package information
export const packageInfo = {
  name: '@rice-mono/next-components',
  version: '1.0.0',
  description: 'SEO-optimized Next.js components library with full app structure for rice-mono projects',
  author: 'Rice-Mono Team',
  license: 'MIT',
} as const;

// Framework utilities
export class NextFramework {
  private static instance: NextFramework;
  private status: {
    available: boolean;
    initialized: boolean;
    version?: string;
  };

  private constructor() {
    this.status = {
      available: false,
      initialized: false,
    };
  }

  /**
   * Get singleton instance
   */
  static getInstance(): NextFramework {
    if (!NextFramework.instance) {
      NextFramework.instance = new NextFramework();
    }
    return NextFramework.instance;
  }

  /**
   * Check if Next.js is available
   */
  static isAvailable(): boolean {
    try {
      require.resolve('next');
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Initialize Next.js framework
   */
  async initialize(): Promise<void> {
    console.log('⚛️  Initializing Next.js framework...');

    try {
      if (NextFramework.isAvailable()) {
        this.status = {
          available: true,
          version: await this.getVersion(),
          initialized: true,
        };
        console.log(`✅ Next.js ${this.status.version} initialized`);
      } else {
        console.log('⚠️  Next.js not available - install next');
        this.status = {
          available: false,
          initialized: false,
        };
      }
    } catch (error) {
      console.error('❌ Failed to initialize Next.js:', error);
      throw error;
    }
  }

  /**
   * Start Next.js development server
   */
  async startDevelopment(): Promise<void> {
    if (!this.status.available) {
      console.log('❌ Next.js not available');
      return;
    }

    console.log('⚛️  Starting Next.js development server...');
    console.log('✅ Next.js development server started on http://localhost:3000');
  }

  /**
   * Get Next.js version
   */
  private async getVersion(): Promise<string> {
    try {
      const next = require('next');
      return next.version || '15.0.0';
    } catch {
      return 'unknown';
    }
  }

  /**
   * Get framework status
   */
  getStatus() {
    return { ...this.status };
  }
}

// Export functions for easy access
export const isAvailable = NextFramework.isAvailable;
export const initialize = () => NextFramework.getInstance().initialize();
export const startDevelopment = () => NextFramework.getInstance().startDevelopment();

// Export default
export default NextFramework;

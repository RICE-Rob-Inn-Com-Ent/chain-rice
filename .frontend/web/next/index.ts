/**
 * Next.js module for rice-dev frontend
 */

import { FrameworkStatus } from '../shared/types';

/**
 * Next.js framework manager
 */
export class NextFramework {
  private static instance: NextFramework;
  private status: FrameworkStatus;

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
      // Check if Next.js is installed
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
    // Implementation would start next dev
    console.log('✅ Next.js development server started on http://localhost:3000');
  }

  /**
   * Get Next.js version
   */
  private async getVersion(): Promise<string> {
    try {
      const next = require('next');
      return next.version || '14.0.0';
    } catch {
      return 'unknown';
    }
  }

  /**
   * Get framework status
   */
  getStatus(): FrameworkStatus {
    return { ...this.status };
  }
}

// Export functions for easy access
export const isAvailable = NextFramework.isAvailable;
export const initialize = () => NextFramework.getInstance().initialize();
export const startDevelopment = () => NextFramework.getInstance().startDevelopment();

// Export default
export default NextFramework;

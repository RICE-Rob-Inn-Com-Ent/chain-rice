/**
 * Shared utilities for rice-dev frontend
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import { initializeLogger, getLogger } from './logger';

const execAsync = promisify(exec);

/**
 * Utility functions for common operations
 */
export class Utils {
  /**
   * Initialize utilities
   */
  static initialize(): void {
    console.log('🔧 Utils initialized');
    
    // Initialize logger
    try {
      initializeLogger({
        baseUrl: process.env.REACT_APP_BACKEND_URL || 'http://localhost:8080',
        endpoint: '/api/logs'
      });
      console.log('📝 Logger initialized');
    } catch (error) {
      console.warn('Failed to initialize logger:', error);
    }
  }

  /**
   * Get logger instance
   */
  static getLogger() {
    return getLogger();
  }

  /**
   * Run tests for all projects
   */
  static async runTests(): Promise<void> {
    try {
      console.log('Running Jest tests...');
      const { stdout } = await execAsync('npm test');
      console.log(stdout);
    } catch (error) {
      console.error('Test execution failed:', error);
    }
  }

  /**
   * Build all projects
   */
  static async buildAll(): Promise<void> {
    try {
      console.log('Building TypeScript...');
      const { stdout } = await execAsync('npx tsc');
      console.log('✅ TypeScript build completed');
      console.log(stdout);
    } catch (error) {
      console.error('Build failed:', error);
    }
  }

  /**
   * Format code with Prettier
   */
  static async formatCode(): Promise<void> {
    try {
      console.log('Formatting code with Prettier...');
      const { stdout } = await execAsync('npx prettier --write .');
      console.log('✅ Code formatted');
      console.log(stdout);
    } catch (error) {
      console.error('Formatting failed:', error);
    }
  }

  /**
   * Lint code with ESLint
   */
  static async lintCode(): Promise<void> {
    try {
      console.log('Linting code with ESLint...');
      const { stdout } = await execAsync('npx eslint . --ext .ts,.tsx');
      console.log('✅ Code linted');
      console.log(stdout);
    } catch (error) {
      console.error('Linting failed:', error);
    }
  }
}

// Initialize utils
export function initialize(): void {
  Utils.initialize();
}

// Export default
export default Utils;

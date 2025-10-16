#!/usr/bin/env node

/**
 * Main TypeScript entry point for rice-dev frontend
 * 
 * This file serves as the central hub for all TypeScript projects:
 * - Angular applications
 * - Next.js applications  
 * - Nuxt.js applications
 * - Shared utilities
 */

import { createInterface } from 'readline';

// Import shared utilities
import * as utils from './shared/utils';
import * as types from './shared/types';

// Import framework-specific modules
import * as angular from './angular';
import * as next from './next';
import * as nuxt from './nuxt';
import * as svelte from './svelte';

/**
 * Main application class
 */
class RiceDevFrontend {
  private rl: any;

  constructor() {
    this.rl = createInterface({
      input: process.stdin,
      output: process.stdout,
    });
  }

  /**
   * Initialize the frontend application
   */
  async initialize(): Promise<void> {
    console.log('🚀 Rice Dev Frontend Initializing...');
    
    try {
      // Initialize shared utilities
      await this.initializeShared();
      
      // Initialize framework modules
      await this.initializeFrameworks();
      
      console.log('✅ Rice Dev Frontend initialized successfully!');
      
      // Start interactive mode
      this.startInteractiveMode();
      
    } catch (error) {
      console.error('❌ Failed to initialize frontend:', error);
      process.exit(1);
    }
  }

  /**
   * Initialize shared utilities
   */
  private async initializeShared(): Promise<void> {
    console.log('📦 Initializing shared utilities...');
    
    // Initialize utilities
    utils.initialize();
    
    console.log('✅ Shared utilities ready');
  }

  /**
   * Initialize framework modules
   */
  private async initializeFrameworks(): Promise<void> {
    console.log('🎨 Initializing frameworks...');
    
    // Initialize Angular
    if (angular.isAvailable()) {
      await angular.initialize();
      console.log('✅ Angular ready');
    }
    
    // Initialize Next.js
    if (next.isAvailable()) {
      await next.initialize();
      console.log('✅ Next.js ready');
    }
    
    // Initialize Nuxt.js
    if (nuxt.isAvailable()) {
      await nuxt.initialize();
      console.log('✅ Nuxt.js ready');
    }
  }

  /**
   * Start interactive mode
   */
  private startInteractiveMode(): void {
    console.log('\n🎯 Interactive mode started. Available commands:');
    console.log('  - angular: Start Angular development');
    console.log('  - next: Start Next.js development');
    console.log('  - nuxt: Start Nuxt.js development');
    console.log('  - test: Run tests');
    console.log('  - build: Build all projects');
    console.log('  - exit: Exit application');
    
    this.promptCommand();
  }

  /**
   * Prompt for command
   */
  private promptCommand(): void {
    this.rl.question('\n> ', async (command: string) => {
      await this.handleCommand(command.trim());
    });
  }

  /**
   * Handle user command
   */
  private async handleCommand(command: string): Promise<void> {
    switch (command.toLowerCase()) {
      case 'angular':
        await this.startAngular();
        break;
      case 'next':
        await this.startNext();
        break;
      case 'nuxt':
        await this.startNuxt();
        break;
      case 'test':
        await this.runTests();
        break;
      case 'build':
        await this.buildAll();
        break;
      case 'exit':
        this.exit();
        break;
      default:
        console.log('❌ Unknown command. Type "exit" to quit.');
        this.promptCommand();
    }
  }

  /**
   * Start Angular development
   */
  private async startAngular(): Promise<void> {
    console.log('🅰️  Starting Angular development...');
    await angular.startDevelopment();
    this.promptCommand();
  }

  /**
   * Start Next.js development
   */
  private async startNext(): Promise<void> {
    console.log('⚛️  Starting Next.js development...');
    await next.startDevelopment();
    this.promptCommand();
  }

  /**
   * Start Nuxt.js development
   */
  private async startNuxt(): Promise<void> {
    console.log('🟢 Starting Nuxt.js development...');
    await nuxt.startDevelopment();
    this.promptCommand();
  }

  /**
   * Run all tests
   */
  private async runTests(): Promise<void> {
    console.log('🧪 Running tests...');
    await utils.runTests();
    this.promptCommand();
  }

  /**
   * Build all projects
   */
  private async buildAll(): Promise<void> {
    console.log('🔨 Building all projects...');
    await utils.buildAll();
    this.promptCommand();
  }

  /**
   * Exit application
   */
  private exit(): void {
    console.log('👋 Goodbye!');
    this.rl.close();
    process.exit(0);
  }
}

// Export for module usage
export { RiceDevFrontend };

// Run if called directly
if (require.main === module) {
  const app = new RiceDevFrontend();
  app.initialize().catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}

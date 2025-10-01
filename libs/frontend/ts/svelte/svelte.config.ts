import adapter from '@sveltejs/adapter-auto';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  // Consult https://kit.svelte.dev/docs/integrations#preprocessors
  // for more information about preprocessors
  preprocess: vitePreprocess(),

  kit: {
    // adapter-auto only supports some environments, see https://kit.svelte.dev/docs/adapter-auto for a list.
    // If your environment is not supported or you settled on a specific environment, switch out the adapter.
    // See https://kit.svelte.dev/docs/adapters for more information about adapters.
    adapter: adapter(),
    
    // Configure paths
    paths: {
      base: process.env.NODE_ENV === 'production' ? '/svelte-app' : '',
    },
    
    // Configure service worker
    serviceWorker: {
      register: false,
    },
    
    // Configure CSP
    csp: {
      directives: {
        'script-src': ['self'],
        'style-src': ['self', 'unsafe-inline'],
      },
    },
    
    // Configure prerender
    prerender: {
      handleHttpError: 'warn',
      handleMissingId: 'warn',
    },
    
    // Configure version
    version: {
      name: process.env.npm_package_version || '1.0.0',
      pollInterval: 0,
    },
  },
  
  // Configure compiler options
  compilerOptions: {
    enableSourcemap: true,
    generate: 'dom',
    hydratable: true,
  },
  
  // Configure extensions
  extensions: ['.svelte'],
  
  // Configure preprocessors
  preprocess: [
    vitePreprocess(),
    // Add other preprocessors here if needed
  ],
};

export default config;

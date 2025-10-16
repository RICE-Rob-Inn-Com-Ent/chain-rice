// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  // Enable TypeScript
  typescript: {
    strict: true,
    typeCheck: true,
  },

  // Enable devtools in development
  devtools: { enabled: true },

  // Configure CSS framework
  css: [
    '~/assets/css/main.css',
  ],

  // Configure modules
  modules: [
    '@nuxtjs/tailwindcss',
    '@nuxtjs/i18n',
    '@pinia/nuxt',
    '@vueuse/nuxt',
    '@nuxt/ui',
  ],

  // Configure Tailwind CSS
  tailwindcss: {
    config: {
      content: [
        './components/**/*.{js,vue,ts}',
        './layouts/**/*.vue',
        './pages/**/*.vue',
        './plugins/**/*.{js,ts}',
        './nuxt.config.{js,ts}',
        './app.vue',
      ],
    },
  },

  // Configure i18n
  i18n: {
    locales: [
      {
        code: 'en',
        name: 'English',
        file: 'en.json',
      },
      {
        code: 'uk',
        name: 'Українська',
        file: 'uk.json',
      },
      {
        code: 'ru',
        name: 'Русский',
        file: 'ru.json',
      },
    ],
    lazy: true,
    langDir: 'locales/',
    defaultLocale: 'en',
    strategy: 'prefix_except_default',
  },

  // Configure runtime config
  runtimeConfig: {
    // Private keys (only available on server-side)
    apiSecret: '123',
    // Public keys (exposed to client-side)
    public: {
      apiBase: process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:3000/api',
    },
  },

  // Configure build
  build: {
    transpile: ['chart.js', 'vue-chartjs'],
  },

  // Configure vite
  vite: {
    css: {
      preprocessorOptions: {
        scss: {
          additionalData: '@use "~/assets/scss/_variables.scss" as *;',
        },
      },
    },
    optimizeDeps: {
      include: ['chart.js', 'vue-chartjs'],
    },
  },

  // Configure app
  app: {
    head: {
      title: 'Nuxt App',
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { hid: 'description', name: 'description', content: 'Nuxt.js application' },
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' },
      ],
    },
  },

  // Configure nitro
  nitro: {
    experimental: {
      wasm: true,
    },
  },

  // Configure experimental features
  experimental: {
    payloadExtraction: false,
  },
});

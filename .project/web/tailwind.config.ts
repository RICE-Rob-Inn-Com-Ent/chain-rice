import type { Config } from 'tailwindcss'

export default {
  darkMode: 'class',
  content: [
    './app/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './pages/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      container: {
        center: true,
        padding: '1rem',
        screens: {
          '2xl': '1280px'
        }
      },
      fontFamily: {
        sans: [
          'var(--font-inter)',
          'var(--font-poppins)',
          'ui-sans-serif',
          'system-ui',
          '-apple-system',
          'Segoe UI',
          'Roboto',
          'Helvetica',
          'Arial',
          '"Apple Color Emoji"',
          '"Segoe UI Emoji"'
        ],
        display: [
          'var(--font-orbitron)',
          'var(--font-poppins)',
          'ui-sans-serif',
          'system-ui'
        ]
      },
      colors: {
        brand: {
          start: '#ff00ff', // magenta (logo)
          end: '#00ffff' // cyan (logo)
        }
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)'
      },
      boxShadow: {
        neon: '0 0 20px rgba(255,0,255,0.35), 0 0 40px rgba(0,255,255,0.25)'
      },
      backgroundImage: {
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
        'gradient-conic': 'conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))',
        'gradient-brand': 'linear-gradient(90deg, var(--brand-grad-start) 0%, var(--brand-grad-end) 100%)'
      },
      keyframes: {
        'fade-in-up': {
          '0%': { opacity: '0', transform: 'translateY(12px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' }
        }
      },
      animation: {
        'fade-in': 'fade-in-up 1.1s ease-in forwards'
      }
    }
  },
  plugins: []
} satisfies Config

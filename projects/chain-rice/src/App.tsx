import React from 'react'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ThemeProvider, createTheme } from '@mui/material/styles'
import { CssBaseline } from '@mui/material'
import { Toaster } from 'react-hot-toast'
import { HelmetProvider } from 'react-helmet-async'

// Pages
import Dashboard from './pages/Dashboard'
import TokenBalances from './pages/TokenBalances'
import TokenTransfer from './pages/TokenTransfer'
import ContractDeploy from './pages/ContractDeploy'
import BlockExplorer from './pages/BlockExplorer'
import Settings from './pages/Settings'

// Components
import Layout from './components/Layout'
import ErrorBoundary from './components/ErrorBoundary'

// Theme
const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#667eea',
    },
    secondary: {
      main: '#764ba2',
    },
    background: {
      default: '#0f0f23',
      paper: '#1a1a2e',
    },
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
  },
})

// Query client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 3,
      refetchOnWindowFocus: false,
    },
  },
})

function App() {
  return (
    <ErrorBoundary>
      <HelmetProvider>
        <QueryClientProvider client={queryClient}>
          <ThemeProvider theme={theme}>
            <CssBaseline />
            <Router>
              <Layout>
                <Routes>
                  <Route path="/" element={<Dashboard />} />
                  <Route path="/balances" element={<TokenBalances />} />
                  <Route path="/transfer" element={<TokenTransfer />} />
                  <Route path="/deploy" element={<ContractDeploy />} />
                  <Route path="/explorer" element={<BlockExplorer />} />
                  <Route path="/settings" element={<Settings />} />
                </Routes>
              </Layout>
              <Toaster
                position="top-right"
                toastOptions={{
                  duration: 4000,
                  style: {
                    background: '#1a1a2e',
                    color: '#fff',
                    border: '1px solid #667eea',
                  },
                }}
              />
            </Router>
          </ThemeProvider>
        </QueryClientProvider>
      </HelmetProvider>
    </ErrorBoundary>
  )
}

export default App

import React from 'react'
import { Alert, Box, Typography } from '@mui/material'

interface ErrorBoundaryState {
  hasError: boolean
  error?: Error
}

interface ErrorBoundaryProps {
  children: React.ReactNode
}

class ErrorBoundary extends React.Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props)
    this.state = { hasError: false }
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo)
  }

  render() {
    if (this.state.hasError) {
      return (
        <Box sx={{ p: 3 }}>
          <Alert severity="error">
            <Typography variant="h6">Something went wrong!</Typography>
            <Typography variant="body2" sx={{ mt: 1 }}>
              {this.state.error?.message || 'An unexpected error occurred'}
            </Typography>
          </Alert>
        </Box>
      )
    }

    return this.props.children
  }
}

export default ErrorBoundary

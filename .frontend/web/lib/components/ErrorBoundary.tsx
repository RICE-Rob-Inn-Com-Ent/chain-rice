import React, { Component, ErrorInfo, ReactNode } from "react";

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfo | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null,
    };
  }

  static getDerivedStateFromError(error: Error): Partial<State> {
    return {
      hasError: true,
      error,
    };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    console.error("ErrorBoundary caught an error:", error, errorInfo);
    this.setState({
      error,
      errorInfo,
    });
  }

  handleReset = (): void => {
    this.setState({
      hasError: false,
      error: null,
      errorInfo: null,
    });
  };

  render(): ReactNode {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }

      return (
        <div className="min-h-screen bg-gradient-to-br from-red-900 to-slate-900 flex items-center justify-center p-4">
          <div className="max-w-2xl w-full bg-white/10 backdrop-blur-lg rounded-xl border border-white/20 p-8">
            <div className="flex items-center gap-3 mb-4">
              <span className="text-4xl">⚠️</span>
              <h1 className="text-2xl font-bold text-white">Something went wrong</h1>
            </div>

            <div className="bg-red-900/30 border border-red-500/30 rounded-lg p-4 mb-6">
              <h2 className="text-lg font-semibold text-red-400 mb-2">Error Details:</h2>
              <p className="text-gray-300 font-mono text-sm">{this.state.error?.message || "Unknown error"}</p>
            </div>

            {process.env.NODE_ENV === "development" && this.state.errorInfo && (
              <details className="mb-6">
                <summary className="text-white cursor-pointer hover:text-gray-300 mb-2">
                  Stack Trace (Development Only)
                </summary>
                <pre className="bg-black/30 p-4 rounded-lg text-xs text-gray-400 overflow-auto max-h-64">
                  {this.state.errorInfo.componentStack}
                </pre>
              </details>
            )}

            <div className="flex gap-3">
              <button
                onClick={this.handleReset}
                className="px-6 py-3 bg-white text-red-900 rounded-lg font-semibold hover:bg-gray-100 transition"
              >
                Try Again
              </button>
              <button
                onClick={() => window.location.reload()}
                className="px-6 py-3 bg-red-600 text-white rounded-lg font-semibold hover:bg-red-700 transition"
              >
                Reload Page
              </button>
            </div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}


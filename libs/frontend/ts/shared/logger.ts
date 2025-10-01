/**
 * Logging module for rice-dev frontend
 * Provides centralized logging with backend integration
 */

export enum LogLevel {
  DEBUG = 'debug',
  INFO = 'info',
  WARN = 'warn',
  ERROR = 'error'
}

export interface LogEntry {
  level: LogLevel;
  message: string;
  timestamp: Date;
  context?: Record<string, any>;
  userId?: string;
  sessionId?: string;
}

export interface BackendLogConfig {
  baseUrl: string;
  endpoint: string;
  apiKey?: string;
  batchSize: number;
  flushInterval: number;
}

/**
 * Logger class for frontend applications
 */
export class Logger {
  private static instance: Logger;
  private logQueue: LogEntry[] = [];
  private config: BackendLogConfig;
  private flushTimer?: NodeJS.Timeout;

  private constructor(config: BackendLogConfig) {
    this.config = config;
    this.startFlushTimer();
  }

  /**
   * Get singleton instance
   */
  static getInstance(config?: BackendLogConfig): Logger {
    if (!Logger.instance) {
      if (!config) {
        throw new Error('Logger must be initialized with config first');
      }
      Logger.instance = new Logger(config);
    }
    return Logger.instance;
  }

  /**
   * Initialize logger with backend configuration
   */
  static initialize(config: BackendLogConfig): Logger {
    return Logger.getInstance(config);
  }

  /**
   * Log debug message
   */
  debug(message: string, context?: Record<string, any>): void {
    this.log(LogLevel.DEBUG, message, context);
  }

  /**
   * Log info message
   */
  info(message: string, context?: Record<string, any>): void {
    this.log(LogLevel.INFO, message, context);
  }

  /**
   * Log warning message
   */
  warn(message: string, context?: Record<string, any>): void {
    this.log(LogLevel.WARN, message, context);
  }

  /**
   * Log error message
   */
  error(message: string, context?: Record<string, any>): void {
    this.log(LogLevel.ERROR, message, context);
  }

  /**
   * Log user action
   */
  userAction(action: string, context?: Record<string, any>): void {
    this.log(LogLevel.INFO, `User action: ${action}`, {
      ...context,
      type: 'user_action'
    });
  }

  /**
   * Log API call
   */
  apiCall(method: string, url: string, status?: number, context?: Record<string, any>): void {
    this.log(LogLevel.INFO, `API call: ${method} ${url}`, {
      ...context,
      type: 'api_call',
      method,
      url,
      status
    });
  }

  /**
   * Log performance metric
   */
  performance(metric: string, value: number, unit: string, context?: Record<string, any>): void {
    this.log(LogLevel.INFO, `Performance: ${metric}`, {
      ...context,
      type: 'performance',
      metric,
      value,
      unit
    });
  }

  /**
   * Internal log method
   */
  private log(level: LogLevel, message: string, context?: Record<string, any>): void {
    const entry: LogEntry = {
      level,
      message,
      timestamp: new Date(),
      context,
      userId: this.getUserId(),
      sessionId: this.getSessionId()
    };

    // Add to queue
    this.logQueue.push(entry);

    // Console logging for development
    if (process.env.NODE_ENV === 'development') {
      console.log(`[${level.toUpperCase()}] ${message}`, context || '');
    }

    // Flush if queue is full
    if (this.logQueue.length >= this.config.batchSize) {
      this.flush();
    }
  }

  /**
   * Flush logs to backend
   */
  async flush(): Promise<void> {
    if (this.logQueue.length === 0) return;

    const logs = [...this.logQueue];
    this.logQueue = [];

    try {
      const response = await fetch(`${this.config.baseUrl}${this.config.endpoint}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(this.config.apiKey && { 'Authorization': `Bearer ${this.config.apiKey}` })
        },
        body: JSON.stringify({ logs })
      });

      if (!response.ok) {
        console.error('Failed to send logs to backend:', response.statusText);
        // Re-add logs to queue for retry
        this.logQueue.unshift(...logs);
      }
    } catch (error) {
      console.error('Error sending logs to backend:', error);
      // Re-add logs to queue for retry
      this.logQueue.unshift(...logs);
    }
  }

  /**
   * Start flush timer
   */
  private startFlushTimer(): void {
    this.flushTimer = setInterval(() => {
      this.flush();
    }, this.config.flushInterval);
  }

  /**
   * Stop flush timer
   */
  stop(): void {
    if (this.flushTimer) {
      clearInterval(this.flushTimer);
      this.flushTimer = undefined;
    }
    // Flush remaining logs
    this.flush();
  }

  /**
   * Get user ID from localStorage or session
   */
  private getUserId(): string | undefined {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('userId') || sessionStorage.getItem('userId') || undefined;
    }
    return undefined;
  }

  /**
   * Get session ID
   */
  private getSessionId(): string | undefined {
    if (typeof window !== 'undefined') {
      return sessionStorage.getItem('sessionId') || undefined;
    }
    return undefined;
  }
}

/**
 * Default logger configuration
 */
export const defaultLogConfig: BackendLogConfig = {
  baseUrl: process.env.REACT_APP_BACKEND_URL || 'http://localhost:8080',
  endpoint: '/api/logs',
  batchSize: 10,
  flushInterval: 5000 // 5 seconds
};

/**
 * Initialize logger with default configuration
 */
export function initializeLogger(config?: Partial<BackendLogConfig>): Logger {
  const finalConfig = { ...defaultLogConfig, ...config };
  return Logger.initialize(finalConfig);
}

/**
 * Get logger instance
 */
export function getLogger(): Logger {
  return Logger.getInstance();
}

// Export default
export default Logger;

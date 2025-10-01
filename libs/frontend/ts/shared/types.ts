/**
 * Shared types for rice-dev frontend
 */

/**
 * Common API response interface
 */
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

/**
 * User interface
 */
export interface User {
  id: string;
  email: string;
  name: string;
  avatar?: string;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Project interface
 */
export interface Project {
  id: string;
  name: string;
  description?: string;
  type: 'angular' | 'next' | 'nuxt' | 'svelte' | 'shared';
  status: 'active' | 'inactive' | 'archived';
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Configuration interface
 */
export interface Config {
  apiUrl: string;
  environment: 'development' | 'staging' | 'production';
  features: {
    angular: boolean;
    next: boolean;
    nuxt: boolean;
    testing: boolean;
  };
}

/**
 * Framework status interface
 */
export interface FrameworkStatus {
  available: boolean;
  version?: string;
  initialized: boolean;
}

/**
 * Command interface for interactive mode
 */
export interface Command {
  name: string;
  description: string;
  handler: () => Promise<void>;
}

/**
 * Error types
 */
export enum ErrorType {
  VALIDATION = 'VALIDATION_ERROR',
  NETWORK = 'NETWORK_ERROR',
  AUTHENTICATION = 'AUTH_ERROR',
  AUTHORIZATION = 'AUTHZ_ERROR',
  NOT_FOUND = 'NOT_FOUND_ERROR',
  SERVER = 'SERVER_ERROR',
}

/**
 * Custom error class
 */
export class RiceDevError extends Error {
  public type: ErrorType;
  public code: string;
  public statusCode: number;

  constructor(
    message: string,
    type: ErrorType = ErrorType.SERVER,
    code: string = 'UNKNOWN_ERROR',
    statusCode: number = 500
  ) {
    super(message);
    this.name = 'RiceDevError';
    this.type = type;
    this.code = code;
    this.statusCode = statusCode;
  }
}

// Export default
export default {
  ApiResponse,
  User,
  Project,
  Config,
  FrameworkStatus,
  Command,
  ErrorType,
  RiceDevError,
};

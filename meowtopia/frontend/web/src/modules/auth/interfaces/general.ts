export interface AuthConfig {
  // Authentication Settings
  auth: {
    enableRememberMe: boolean;
    enableSocialLogin: boolean;
    enableEmailVerification: boolean;
    enableTwoFactor: boolean;
    sessionTimeout: number;
    maxLoginAttempts: number;
    lockoutDuration: number;
  };

  // Password Policy
  passwordPolicy: {
    minLength: number;
    requireUppercase: boolean;
    requireLowercase: boolean;
    requireNumbers: boolean;
    requireSpecialChars: boolean;
    preventCommonPasswords: boolean;
    preventPersonalInfo: boolean;
  };
}

export interface AuthState {
  isAuthenticated: boolean;
  user: User | null;
  loading: boolean;
  error: string | null;
  success: string | null;
}

export interface User {
  id: string;
  email: string;
  fullName: string;
  role: "USER" | "ADMIN";
  avatar?: string;
  emailVerified: boolean;
  createdAt: string;
  lastLogin?: string;
}

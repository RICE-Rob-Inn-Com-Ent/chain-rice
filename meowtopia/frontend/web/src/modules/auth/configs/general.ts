// ============================================================================
// AUTH GENERAL CONFIGURATION
// ============================================================================

export const authSettings = {
  enableRememberMe: true,
  enableSocialLogin: true,
  enableEmailVerification: true,
  enableTwoFactor: false,
  sessionTimeout: 1440,
  maxLoginAttempts: 5,
  lockoutDuration: 15,
};

export const passwordPolicy = {
  minLength: 8,
  requireUppercase: true,
  requireLowercase: true,
  requireNumbers: true,
  requireSpecialChars: true,
  preventCommonPasswords: true,
  preventPersonalInfo: true,
};
// ============================================================================
// AUTH INTERFACES INDEX
// ============================================================================

// Export all interfaces from their respective files
export * from "./api";
export * from "./general";
export * from "./pages";

// ============================================================================
// VALIDATION INTERFACES
// ============================================================================

export interface ValidationRule {
  type: "required" | "email" | "minLength" | "maxLength" | "pattern" | "custom";
  message: string;
  value?: number | string;
  custom?: (value: string) => boolean;
}

// ============================================================================
// STYLE INTERFACES
// ============================================================================

export interface LoginStyles {
  container: string;
  form: string;
  title: string;
  subtitle: string;
  socialContainer: string;
  socialButton: string;
  divider: string;
  button: string;
  link: string;
  success: string;
}

export interface RegisterStyles {
  container: string;
  form: string;
  title: string;
  subtitle: string;
  socialContainer: string;
  socialButton: string;
  divider: string;
  button: string;
  link: string;
  success: string;
  passwordStrength: string;
}

export interface ForgotPasswordStyles {
  container: string;
  form: string;
  title: string;
  subtitle: string;
  button: string;
  link: string;
  success: string;
}

export interface ResetPasswordStyles {
  container: string;
  form: string;
  title: string;
  subtitle: string;
  button: string;
  link: string;
  success: string;
  passwordStrength: string;
}

export interface CommonStyles {
  container: string;
  form: string;
  title: string;
  subtitle: string;
  button: string;
  link: string;
  success: string;
  error: string;
  // Additional properties used in styles.ts
  primaryButton: string;
  secondaryButton: string;
  outlineButton: string;
  ghostButton: string;
  dangerButton: string;
  input: string;
  label: string;
  loading: string;
} 
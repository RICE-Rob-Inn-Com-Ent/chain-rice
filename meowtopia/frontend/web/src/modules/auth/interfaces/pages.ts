export interface LoginFormData {
  email: string;
  password: string;
  rememberMe: boolean;
}

export interface RegisterFormData {
  fullName: string;
  email: string;
  password: string;
  confirmPassword: string;
  terms: boolean;
  marketing?: boolean;
}

export interface ForgotPasswordFormData {
  email: string;
}

export interface ResetPasswordFormData {
  password: string;
  confirmPassword: string;
}

// Unified interface for all auth pages
export interface AuthMessages {
  title: string;
  subtitle: string;
  loading: string;
  error: string;
  success: string;
  backToLogin?: string;
  forgotPassword?: string;
  noAccount?: string;
  hasAccount?: string;
  orDivider?: string;
  passwordMismatch?: string;
  termsRequired?: string;
  passwordRequirements?: string;
  fields: {
    fullName?: import("../../../global").FieldConfig;
    email?: import("../../../global").FieldConfig;
    password?: import("../../../global").FieldConfig;
    confirmPassword?: import("../../../global").FieldConfig;
    rememberMe?: { label: string };
    terms?: { label: string };
    marketing?: { label: string };
  };
  buttons: {
    login?: string;
    register?: string;
    forgotPassword?: string;
    sendReset?: string;
    resetPassword?: string;
    backToLogin?: string;
  };
  errors: {
    invalidCredentials?: string;
    accountLocked?: string;
    emailNotVerified?: string;
    tooManyAttempts?: string;
    emailExists?: string;
    weakPassword?: string;
    invalidEmail?: string;
    emailNotFound?: string;
    tooManyRequests?: string;
    invalidToken?: string;
    expiredToken?: string;
    passwordMismatch?: string;
    networkError: string;
  };
}

// Specific interfaces for type safety (extending the unified interface)
export interface LoginMessages extends AuthMessages {
  forgotPassword: string;
  noAccount: string;
  orDivider: string;
  fields: {
    email: import("../../../global").FieldConfig;
    password: import("../../../global").FieldConfig;
    rememberMe: { label: string };
  };
  buttons: {
    login: string;
    forgotPassword: string;
    register: string;
  };
  errors: {
    invalidCredentials: string;
    accountLocked: string;
    emailNotVerified: string;
    tooManyAttempts: string;
    networkError: string;
  };
}

export interface RegisterMessages extends AuthMessages {
  passwordMismatch: string;
  termsRequired: string;
  hasAccount: string;
  orDivider: string;
  passwordRequirements: string;
  fields: {
    fullName: import("../../../global").FieldConfig;
    email: import("../../../global").FieldConfig;
    password: import("../../../global").FieldConfig;
    confirmPassword: import("../../../global").FieldConfig;
    terms: { label: string };
    marketing?: { label: string };
  };
  buttons: {
    register: string;
    login: string;
  };
  errors: {
    emailExists: string;
    weakPassword: string;
    invalidEmail: string;
    networkError: string;
  };
}

export interface ForgotPasswordMessages extends AuthMessages {
  backToLogin: string;
  fields: {
    email: import("../../../global").FieldConfig;
  };
  buttons: {
    sendReset: string;
    backToLogin: string;
  };
  errors: {
    emailNotFound: string;
    tooManyRequests: string;
    networkError: string;
  };
}

export interface ResetPasswordMessages extends AuthMessages {
  backToLogin: string;
  fields: {
    password: import("../../../global").FieldConfig;
    confirmPassword: import("../../../global").FieldConfig;
  };
  buttons: {
    resetPassword: string;
    backToLogin: string;
  };
  errors: {
    invalidToken: string;
    expiredToken: string;
    passwordMismatch: string;
    weakPassword: string;
    networkError: string;
  };
}

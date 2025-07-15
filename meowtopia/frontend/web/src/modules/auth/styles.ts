// ============================================================================
// AUTHENTICATION STYLES CONFIGURATION
// ============================================================================

import { 
  LoginStyles, 
  RegisterStyles, 
  ForgotPasswordStyles, 
  ResetPasswordStyles, 
  CommonStyles 
} from './interfaces';

// ============================================================================
// BASE STYLES (Shared across all auth components)
// ============================================================================

const baseStyles = {
  // Layout
  container: "min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8",
  form: "max-w-md w-full space-y-8 bg-white p-8 rounded-lg shadow-md",
  
  // Typography
  title: "text-center text-3xl font-extrabold text-gray-900 mb-2",
  subtitle: "text-center text-sm text-gray-600 mb-8",
  
  // Social
  socialContainer: "space-y-3",
  socialButton: "w-full flex justify-center items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500",
  divider: "relative my-6",
  
  // Interactive Elements
  link: "text-indigo-600 hover:text-indigo-500 text-sm",
  field: "space-y-1",
  button: "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500",
  
  // Feedback
  error: "text-red-600 text-sm",
  success: "text-green-600 text-sm",
  
  // Special Elements
  passwordStrength: "text-xs mt-1",
};

// ============================================================================
// COMPONENT-SPECIFIC STYLES (Extend base styles)
// ============================================================================

export const loginStyles: LoginStyles = {
  ...baseStyles,
};

export const registerStyles: RegisterStyles = {
  ...baseStyles,
};

export const forgotPasswordStyles: ForgotPasswordStyles = {
  ...baseStyles,
};

export const resetPasswordStyles: ResetPasswordStyles = {
  ...baseStyles,
};

// ============================================================================
// COMMON STYLES (For general use)
// ============================================================================

export const commonStyles: CommonStyles = {
  // Required base properties
  container: baseStyles.container,
  form: baseStyles.form,
  title: baseStyles.title,
  subtitle: baseStyles.subtitle,
  button: baseStyles.button,
  link: baseStyles.link,
  success: baseStyles.success,
  error: baseStyles.error,
  // Button Variants
  primaryButton: "bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500",
  secondaryButton: "bg-gray-600 hover:bg-gray-700 text-white px-4 py-2 rounded-md text-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500",
  outlineButton: "border border-gray-300 text-gray-700 bg-white hover:bg-gray-50 px-4 py-2 rounded-md text-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500",
  ghostButton: "text-gray-700 hover:text-gray-900 px-4 py-2 rounded-md text-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500",
  dangerButton: "bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-md text-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500",
  // Form Elements
  input: "appearance-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm",
  label: "block text-sm font-medium text-gray-700",
  // Feedback
  loading: "animate-spin rounded-full h-4 w-4 border-b-2 border-white",
};

// ============================================================================
// UNIFIED AUTH STYLES (All styles in one object for easy access)
// ============================================================================

export const authStyles = {
  // Base styles (shared across all components)
  ...baseStyles,
  
  // Component-specific styles
  login: loginStyles,
  register: registerStyles,
  forgotPassword: forgotPasswordStyles,
  resetPassword: resetPasswordStyles,
  
  // Common styles
  common: commonStyles,
  
  // Button variants
  buttons: {
    primary: commonStyles.primaryButton,
    secondary: commonStyles.secondaryButton,
    outline: commonStyles.outlineButton,
    ghost: commonStyles.ghostButton,
    danger: commonStyles.dangerButton,
  },
  
  // Form elements
  forms: {
    input: commonStyles.input,
    label: commonStyles.label,
    field: baseStyles.field,
  },
  
  // Feedback
  feedback: {
    error: baseStyles.error,
    success: baseStyles.success,
    loading: commonStyles.loading,
  },
}; 
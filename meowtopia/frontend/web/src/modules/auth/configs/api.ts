// ============================================================================
// API ENDPOINTS CONFIGURATION
// ============================================================================

import type { ApiEndpoint, SocialProvider } from '../interfaces/api';

export const apiEndpoints: { endpoints: { [key: string]: ApiEndpoint } } = {
  endpoints: {
    login: {
      url: "/api/v1/auth/login",
      method: "POST",
      headers: { 
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      timeout: 10000,
      retryAttempts: 3,
    },
    register: {
      url: "/api/v1/auth/register",
      method: "POST",
      headers: { "Content-Type": "application/json" },
      timeout: 10000,
      retryAttempts: 3,
    },
    logout: {
      url: "/api/v1/auth/logout",
      method: "POST",
      headers: { 
        "Content-Type": "application/json",
        "X-CSRF-Token": "${csrfToken}"
      },
      timeout: 5000,
      retryAttempts: 1,
    },
    refresh: {
      url: "/api/v1/auth/refresh",
      method: "POST",
      headers: { "Content-Type": "application/json" },
      timeout: 5000,
      retryAttempts: 2,
    },
    forgotPassword: {
      url: "/api/v1/auth/forgot-password",
      method: "POST",
      headers: { "Content-Type": "application/json" },
      timeout: 10000,
      retryAttempts: 3,
    },
    resetPassword: {
      url: "/api/v1/auth/reset-password",
      method: "POST",
      headers: { "Content-Type": "application/json" },
      timeout: 10000,
      retryAttempts: 3,
    },
    verifyEmail: {
      url: "/api/v1/auth/verify-email",
      method: "POST",
      headers: { "Content-Type": "application/json" },
      timeout: 10000,
      retryAttempts: 3,
    },
    resendVerification: {
      url: "/api/v1/auth/resend-verification",
      method: "POST",
      headers: { "Content-Type": "application/json" },
      timeout: 10000,
      retryAttempts: 3,
    },
    profile: {
      url: "/api/v1/auth/profile",
      method: "GET",
      headers: { 
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer ${token}"
      },
      timeout: 10000,
      retryAttempts: 2,
    },
    updateProfile: {
      url: "/api/v1/auth/profile",
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      timeout: 10000,
      retryAttempts: 3,
    },
    changePassword: {
      url: "/api/v1/auth/change-password",
      method: "POST",
      headers: { "Content-Type": "application/json" },
      timeout: 10000,
      retryAttempts: 3,
    },
    uploadAvatar: {
      url: "/api/v1/auth/avatar",
      method: "POST",
      headers: { 
        "Content-Type": "multipart/form-data"
      },
      timeout: 30000,
      retryAttempts: 1,
    },
  },
};
// ============================================================================
// SOCIAL PROVIDERS API CONFIGURATION
// ============================================================================

export const socialProviders: SocialProvider[] = [
  {
    name: "Google",
    icon: "logos:google",
    color: "#4285F4",
    url: "/api/v1/auth/google",
    enabled: true,
    clientId: import.meta.env.VITE_APP_GOOGLE_CLIENT_ID,
    redirectUri: `${import.meta.env.VITE_APP_BASE_URL}/auth/callback/google`,
  },
  {
    name: "Facebook",
    icon: "logos:meta",
    color: "#1877F2",
    url: "/api/v1/auth/facebook",
    enabled: true,
    clientId: import.meta.env.VITE_APP_FACEBOOK_CLIENT_ID,
    redirectUri: `${import.meta.env.VITE_APP_BASE_URL}/auth/callback/facebook`,
  },
  {
    name: "GitHub",
    icon: "logos:github",
    color: "#333333",
    url: "/api/v1/auth/github",
    enabled: false,
    clientId: import.meta.env.VITE_APP_GITHUB_CLIENT_ID,
    redirectUri: `${import.meta.env.VITE_APP_BASE_URL}/auth/callback/github`,
  },
];


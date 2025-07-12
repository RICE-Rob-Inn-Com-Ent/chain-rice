// ============================================================================
// AUTHENTICATION UTILITY FUNCTIONS
// ============================================================================

import { ValidationRule, ApiEndpoint } from "./interfaces";

// ============================================================================
// VALIDATION UTILITIES
// ============================================================================

export const validateField = (
  value: string,
  rules: ValidationRule[]
): string | null => {
  for (const rule of rules) {
    switch (rule.type) {
      case "required":
        if (!value.trim()) return rule.message;
        break;
      case "email":
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(value)) return rule.message;
        break;
      case "minLength":
        if (typeof rule.value === 'number' && value.length < rule.value) return rule.message;
        break;
      case "maxLength":
        if (typeof rule.value === 'number' && value.length > rule.value) return rule.message;
        break;
      case "pattern":
        if (typeof rule.value === 'string') {
          const patternRegex = new RegExp(rule.value);
          if (!patternRegex.test(value)) return rule.message;
        }
        break;
      case "custom":
        if (rule.custom && !rule.custom(value)) return rule.message;
        break;
    }
  }
  return null;
};

export const validatePassword = (password: string): boolean => {
  // Basic password validation - can be enhanced with config
  const hasMinLength = password.length >= 8;
  const hasUpper = /[A-Z]/.test(password);
  const hasLower = /[a-z]/.test(password);
  const hasNumber = /\d/.test(password);
  const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(password);

  return hasMinLength && hasUpper && hasLower && hasNumber && hasSpecial;
};

export const getPasswordStrengthColor = (password: string): string => {
  if (password.length === 0) return "text-gray-400";
  if (validatePassword(password)) return "text-green-600";
  if (password.length >= 6) return "text-yellow-600";
  return "text-red-600";
};

export const getPasswordStrengthText = (password: string): string => {
  if (password.length === 0) return "";
  if (validatePassword(password)) return "✓ Silne hasło";

  const issues = [];

  if (password.length < 8) {
    issues.push("co najmniej 8 znaków");
  }
  if (!/[A-Z]/.test(password)) {
    issues.push("jedną wielką literę");
  }
  if (!/[a-z]/.test(password)) {
    issues.push("jedną małą literę");
  }
  if (!/\d/.test(password)) {
    issues.push("jedną cyfrę");
  }
  if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    issues.push("jeden znak specjalny");
  }

  return `Brakuje: ${issues.join(", ")}`;
};

// ============================================================================
// API UTILITIES
// ============================================================================

export const makeApiCall = async (
  endpoint: ApiEndpoint,
  data?: any
): Promise<any> => {
  const baseUrl = process.env.REACT_APP_API_URL || "http://localhost:8000";
  const url = `${baseUrl}${endpoint.url}`;

  const config: RequestInit = {
    method: endpoint.method,
    headers: {
      ...endpoint.headers,
      ...(data && { "Content-Type": "application/json" }),
    },
    ...(data && { body: JSON.stringify(data) }),
  };

  let lastError: Error | null = null;

  for (let attempt = 0; attempt <= (endpoint.retryAttempts || 0); attempt++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(
        () => controller.abort(),
        endpoint.timeout || 10000
      );

      const response = await fetch(url, {
        ...config,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(
          errorData.detail || `HTTP ${response.status}: ${response.statusText}`
        );
      }

      return await response.json();
    } catch (error) {
      lastError = error as Error;
      if (attempt === (endpoint.retryAttempts || 0)) {
        throw lastError;
      }
      // Wait before retrying (exponential backoff)
      await new Promise((resolve) =>
        setTimeout(resolve, Math.pow(2, attempt) * 1000)
      );
    }
  }

  throw lastError;
};

export const handleAuthError = (error: any): string => {
  if (error.message.includes("401")) {
    return "Nieprawidłowy adres email lub hasło";
  }
  if (error.message.includes("423")) {
    return "Konto jest tymczasowo zablokowane. Proszę spróbować ponownie później.";
  }
  if (error.message.includes("403")) {
    return "Proszę zweryfikować swój adres email przed zalogowaniem się.";
  }
  if (error.message.includes("429")) {
    return "Za dużo prób logowania. Proszę spróbować ponownie później.";
  }
  if (
    error.message.includes("NetworkError") ||
    error.message.includes("fetch")
  ) {
    return "Błąd połączenia. Proszę sprawdzić swoje połączenie z internetem.";
  }
  return error.message || "Wystąpił błąd";
};

// ============================================================================
// TOKEN UTILITIES
// ============================================================================

export const getStoredToken = (): string | null => {
  return localStorage.getItem("access_token");
};

export const setStoredToken = (token: string): void => {
  localStorage.setItem("access_token", token);
};

export const removeStoredToken = (): void => {
  localStorage.removeItem("access_token");
  localStorage.removeItem("refresh_token");
  localStorage.removeItem("remember_me");
};

export const isTokenExpired = (token: string): boolean => {
  try {
    const payload = JSON.parse(atob(token.split(".")[1]));
    return payload.exp * 1000 < Date.now();
  } catch {
    return true;
  }
};

// ============================================================================
// FORM UTILITIES
// ============================================================================

export const formatFormData = (formData: any): any => {
  const formatted: any = {};

  Object.keys(formData).forEach((key) => {
    const value = formData[key];
    if (value !== null && value !== undefined && value !== "") {
      formatted[key] = value;
    }
  });

  return formatted;
};

export const validateForm = (
  formData: any,
  validationRules: Record<string, ValidationRule[]>
): Record<string, string> => {
  const errors: Record<string, string> = {};

  Object.keys(validationRules).forEach((field) => {
    const value = formData[field];
    const rules = validationRules[field];
    const error = validateField(value, rules);
    if (error) {
      errors[field] = error;
    }
  });

  return errors;
};

// ============================================================================
// STRING UTILITIES
// ============================================================================

export const capitalizeFirst = (str: string): string => {
  return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
};

export const formatErrorMessage = (error: any): string => {
  if (typeof error === "string") return error;
  if (error?.message) return error.message;
  if (error?.detail) return error.detail;
  return "Wystąpił nieoczekiwany błąd";
};

export const sanitizeInput = (input: string): string => {
  return input.trim().replace(/[<>]/g, "");
};

// ============================================================================
// DATE UTILITIES
// ============================================================================

export const formatDate = (
  date: string | Date,
  format: string = "DD/MM/YYYY"
): string => {
  const d = new Date(date);
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  const year = d.getFullYear();

  return format
    .replace("MM", month)
    .replace("DD", day)
    .replace("YYYY", String(year));
};

export const isRecentDate = (
  date: string | Date,
  hours: number = 24
): boolean => {
  const d = new Date(date);
  const now = new Date();
  const diffInHours = (now.getTime() - d.getTime()) / (1000 * 60 * 60);
  return diffInHours <= hours;
};

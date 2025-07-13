// ============================================================================
// STORAGE UTILITY FUNCTIONS
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

export const validateFile = (file: File | null, maxSize: number = 100 * 1024 * 1024): string | null => {
  if (!file) {
    return "Plik jest wymagany";
  }

  // Check file size
  if (file.size > maxSize) {
    return `Plik jest za duży. Maksymalny rozmiar to ${formatFileSize(maxSize)}`;
  }

  // Check file type (basic check)
  const allowedTypes = [
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain', 'text/csv', 'application/json', 'application/xml'
  ];
  
  if (!allowedTypes.includes(file.type)) {
    return "Nieobsługiwany typ pliku";
  }

  return null;
};

export const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

export const getFileIcon = (fileType: string): string => {
  if (fileType.startsWith('image/')) return '📷';
  if (fileType === 'application/pdf') return '📄';
  if (fileType.includes('word')) return '📝';
  if (fileType === 'text/plain') return '📄';
  if (fileType === 'text/csv') return '📊';
  if (fileType === 'application/json') return '📋';
  if (fileType === 'application/xml') return '📋';
  return '📁';
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
      ...(data && !(data instanceof FormData) && { "Content-Type": "application/json" }),
    },
    ...(data && { body: data instanceof FormData ? data : JSON.stringify(data) }),
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

export const handleStorageError = (error: any): string => {
  if (error.message.includes("413")) {
    return "Plik jest za duży";
  }
  if (error.message.includes("415")) {
    return "Nieobsługiwany typ pliku";
  }
  if (error.message.includes("404")) {
    return "Plik nie został znaleziony";
  }
  if (error.message.includes("403")) {
    return "Brak uprawnień do dostępu do tego pliku";
  }
  if (error.message.includes("409")) {
    return "Plik o tej nazwie już istnieje";
  }
  if (error.message.includes("429")) {
    return "Za dużo żądań. Proszę spróbować ponownie później.";
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
// FILE UTILITIES
// ============================================================================

export const generateFileId = (): string => {
  return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
};

export const sanitizeFileName = (fileName: string): string => {
  return fileName
    .replace(/[^a-zA-Z0-9.-]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '');
};

export const getFileExtension = (fileName: string): string => {
  return fileName.split('.').pop()?.toLowerCase() || '';
};

export const isImageFile = (fileType: string): boolean => {
  return fileType.startsWith('image/');
};

export const isDocumentFile = (fileType: string): boolean => {
  return fileType.includes('pdf') || fileType.includes('word') || fileType.includes('document');
};

export const isTextFile = (fileType: string): boolean => {
  return fileType.startsWith('text/') || fileType.includes('json') || fileType.includes('xml');
};

// ============================================================================
// UPLOAD UTILITIES
// ============================================================================

export const createUploadProgressHandler = (onProgress: (progress: number) => void) => {
  return (event: ProgressEvent) => {
    if (event.lengthComputable) {
      const progress = Math.round((event.loaded * 100) / event.total);
      onProgress(progress);
    }
  };
};

export const validateUploadData = (data: any): Record<string, string> => {
  const errors: Record<string, string> = {};

  if (!data.file) {
    errors.file = "Plik jest wymagany";
  }

  if (data.description && data.description.length > 500) {
    errors.description = "Opis nie może być dłuższy niż 500 znaków";
  }

  if (data.tags && data.tags.length > 200) {
    errors.tags = "Tagi nie mogą być dłuższe niż 200 znaków";
  }

  return errors;
};

// ============================================================================
// DOWNLOAD UTILITIES
// ============================================================================

export const downloadFile = (url: string, filename: string): void => {
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
};

export const downloadBlob = (blob: Blob, filename: string): void => {
  const url = window.URL.createObjectURL(blob);
  downloadFile(url, filename);
  window.URL.revokeObjectURL(url);
};

// ============================================================================
// FORM UTILITIES
// ============================================================================

export const validateForm = (
  formData: any,
  validationRules: Record<string, ValidationRule[]>
): Record<string, string> => {
  const errors: Record<string, string> = {};

  for (const [field, rules] of Object.entries(validationRules)) {
    const error = validateField(formData[field] || "", rules);
    if (error) {
      errors[field] = error;
    }
  }

  return errors;
};

export const capitalizeFirst = (str: string): string => {
  return str.charAt(0).toUpperCase() + str.slice(1);
};

export const formatErrorMessage = (error: any): string => {
  if (typeof error === 'string') return error;
  if (error?.message) return error.message;
  return "Wystąpił nieznany błąd";
};

export const sanitizeInput = (input: string): string => {
  return input
    .trim()
    .replace(/[<>]/g, '')
    .replace(/javascript:/gi, '')
    .replace(/on\w+=/gi, '');
};

export const formatDate = (
  date: string | Date,
  format: string = "DD/MM/YYYY"
): string => {
  const d = new Date(date);
  
  if (isNaN(d.getTime())) {
    return "Nieprawidłowa data";
  }

  const day = d.getDate().toString().padStart(2, '0');
  const month = (d.getMonth() + 1).toString().padStart(2, '0');
  const year = d.getFullYear();
  const hours = d.getHours().toString().padStart(2, '0');
  const minutes = d.getMinutes().toString().padStart(2, '0');

  return format
    .replace('DD', day)
    .replace('MM', month)
    .replace('YYYY', year.toString())
    .replace('HH', hours)
    .replace('mm', minutes);
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

// ============================================================================
// STORAGE SPECIFIC UTILITIES
// ============================================================================

export const getStorageQuota = async (): Promise<{ used: number; total: number }> => {
  if ('storage' in navigator && 'estimate' in navigator.storage) {
    const estimate = await navigator.storage.estimate();
    return {
      used: estimate.usage || 0,
      total: estimate.quota || 0
    };
  }
  return { used: 0, total: 0 };
};

export const formatStorageQuota = (bytes: number): string => {
  return formatFileSize(bytes);
};

export const getStorageUsagePercentage = (used: number, total: number): number => {
  if (total === 0) return 0;
  return Math.round((used / total) * 100);
}; 
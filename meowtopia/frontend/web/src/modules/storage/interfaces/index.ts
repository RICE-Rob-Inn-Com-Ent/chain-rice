// ============================================================================
// STORAGE INTERFACES INDEX
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

export interface UploadStyles {
  container: string;
  form: string;
  title: string;
  subtitle: string;
  fileInput: string;
  progressBar: string;
  button: string;
  link: string;
  success: string;
  error: string;
}

export interface DownloadStyles {
  container: string;
  form: string;
  title: string;
  subtitle: string;
  fileList: string;
  fileItem: string;
  button: string;
  link: string;
  success: string;
  error: string;
}

export interface ManageStyles {
  container: string;
  form: string;
  title: string;
  subtitle: string;
  fileGrid: string;
  fileCard: string;
  button: string;
  link: string;
  success: string;
  error: string;
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
  fileInput: string;
  progressBar: string;
  fileList: string;
  fileItem: string;
  fileGrid: string;
  fileCard: string;
} 
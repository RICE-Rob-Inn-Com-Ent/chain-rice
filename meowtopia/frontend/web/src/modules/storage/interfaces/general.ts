// ============================================================================
// STORAGE GENERAL INTERFACES
// ============================================================================

export interface StorageSettings {
  maxFileSize: number;
  allowedFileTypes: string[];
  enablePublicFiles: boolean;
  enableFileSharing: boolean;
  enableFileVersioning: boolean;
  maxFilesPerUser: number;
  storageQuota: number;
}

export interface FileValidationRule {
  maxSize: number;
  allowedTypes: string[];
  maxFilenameLength: number;
  allowSpecialChars: boolean;
}

export interface UploadProgress {
  loaded: number;
  total: number;
  percentage: number;
  speed: number;
  timeRemaining: number;
}

export interface FileMetadata {
  id: string;
  name: string;
  size: number;
  type: string;
  lastModified: Date;
  checksum: string;
  version: number;
}

export interface StorageConfig {
  baseUrl: string;
  apiVersion: string;
  timeout: number;
  retryAttempts: number;
  chunkSize: number;
} 
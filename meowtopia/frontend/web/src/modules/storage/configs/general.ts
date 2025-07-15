// ============================================================================
// STORAGE GENERAL CONFIGURATION
// ============================================================================

export const storageSettings = {
  maxFileSize: 100 * 1024 * 1024, // 100MB
  allowedFileTypes: [
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain', 'text/csv', 'application/json', 'application/xml'
  ],
  enablePublicFiles: true,
  enableFileSharing: true,
  enableFileVersioning: false,
  maxFilesPerUser: 1000,
  storageQuota: 10 * 1024 * 1024 * 1024, // 10GB
};

export const fileValidationRules = {
  maxSize: 100 * 1024 * 1024, // 100MB
  allowedTypes: [
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain', 'text/csv', 'application/json', 'application/xml'
  ],
  maxFilenameLength: 255,
  allowSpecialChars: false,
};

export const uploadConfig = {
  chunkSize: 1024 * 1024, // 1MB chunks
  maxConcurrentUploads: 3,
  retryAttempts: 3,
  timeout: 60000, // 60 seconds
}; 
// ============================================================================
// STORAGE PAGES CONFIGURATION
// ============================================================================

export const storagePageMessages = {
  title: "Storage Management",
  subtitle: "Upload, download, and manage your files",
  upload: "Upload File",
  download: "Download File",
  manage: "Manage Files",
  backToStorage: "Back to Storage",
};

export const uploadMessages = {
  title: "Upload File",
  subtitle: "Select a file to upload to your storage",
  fileRequired: "Plik jest wymagany",
  fileTooLarge: "Plik jest za duży. Maksymalny rozmiar to 100MB",
  invalidFileType: "Nieobsługiwany typ pliku",
  descriptionPlaceholder: "Enter file description (optional)",
  tagsPlaceholder: "Enter tags separated by commas (optional)",
  isPublicLabel: "Make file public",
  uploadButton: "Upload File",
  uploading: "Uploading...",
  success: "File uploaded successfully!",
  error: "Failed to upload file. Please try again.",
  dragAndDrop: "Drag and drop files here, or click to select",
  or: "or",
  browse: "Browse files",
  maxSize: "Maximum file size: 100MB",
  allowedTypes: "Allowed file types: Images, PDFs, Documents, Text files",
};

export const downloadMessages = {
  title: "Download File",
  subtitle: "Enter file ID to download",
  fileIdRequired: "ID pliku jest wymagane",
  fileIdPlaceholder: "Enter file ID",
  downloadButton: "Download File",
  downloading: "Downloading...",
  success: "File downloaded successfully!",
  error: "Failed to download file. Please check the file ID and try again.",
  fileNotFound: "File not found",
  noPermission: "You don't have permission to download this file",
  invalidFileId: "Invalid file ID format",
};

export const manageMessages = {
  title: "Manage Files",
  subtitle: "View and manage your uploaded files",
  deleteButton: "Delete File",
  updateButton: "Update File",
  shareButton: "Share File",
  renameButton: "Rename File",
  processing: "Processing...",
  success: "Operation completed successfully!",
  error: "Failed to complete operation. Please try again.",
  confirmDelete: "Are you sure you want to delete this file?",
  confirmDeleteTitle: "Delete File",
  confirmDeleteMessage: "This action cannot be undone. The file will be permanently deleted.",
  cancel: "Cancel",
  confirm: "Confirm",
  fileDeleted: "File deleted successfully",
  fileUpdated: "File updated successfully",
  fileShared: "File shared successfully",
  fileRenamed: "File renamed successfully",
  noFiles: "No files found",
  searchPlaceholder: "Search files...",
  filterAll: "All files",
  filterImages: "Images",
  filterDocuments: "Documents",
  filterPublic: "Public files",
  filterPrivate: "Private files",
  sortByName: "Sort by name",
  sortBySize: "Sort by size",
  sortByDate: "Sort by date",
  sortByType: "Sort by type",
  sortAsc: "Ascending",
  sortDesc: "Descending",
};

export const storageValidationMessages = {
  required: "This field is required",
  invalidFileType: "Invalid file type",
  fileTooLarge: "File is too large",
  invalidFileId: "Invalid file ID",
  invalidDescription: "Description is too long",
  invalidTags: "Tags are too long",
  networkError: "Network error. Please check your connection",
  serverError: "Server error. Please try again later",
  unauthorized: "You are not authorized to perform this action",
  forbidden: "Access denied",
  notFound: "Resource not found",
  conflict: "Resource already exists",
  tooManyRequests: "Too many requests. Please try again later",
};

export const storageSuccessMessages = {
  uploadSuccess: "File uploaded successfully!",
  downloadSuccess: "File downloaded successfully!",
  deleteSuccess: "File deleted successfully!",
  updateSuccess: "File updated successfully!",
  shareSuccess: "File shared successfully!",
  renameSuccess: "File renamed successfully!",
  quotaUpdated: "Storage quota updated",
  settingsSaved: "Storage settings saved",
};

export const storageErrorMessages = {
  uploadFailed: "Failed to upload file",
  downloadFailed: "Failed to download file",
  deleteFailed: "Failed to delete file",
  updateFailed: "Failed to update file",
  shareFailed: "Failed to share file",
  renameFailed: "Failed to rename file",
  quotaExceeded: "Storage quota exceeded",
  invalidFile: "Invalid file",
  fileNotFound: "File not found",
  permissionDenied: "Permission denied",
  networkError: "Network error",
  serverError: "Server error",
  unknownError: "An unknown error occurred",
}; 
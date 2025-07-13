// ============================================================================
// STORAGE API INTERFACES
// ============================================================================

export interface ApiEndpoint {
  url: string;
  method: "GET" | "POST" | "PUT" | "DELETE" | "PATCH";
  headers?: Record<string, string>;
  timeout?: number;
  retryAttempts?: number;
}

export interface StorageApiResponse {
  success: boolean;
  message: string;
  data?: any;
  error?: string;
}

export interface FileUploadResponse {
  fileId: string;
  filename: string;
  size: number;
  type: string;
  url: string;
  uploadedAt: string;
}

export interface FileDownloadResponse {
  fileId: string;
  filename: string;
  size: number;
  type: string;
  data: Blob;
  downloadUrl: string;
}

export interface FileInfo {
  id: string;
  filename: string;
  size: number;
  type: string;
  description?: string;
  tags?: string[];
  isPublic: boolean;
  uploadedAt: string;
  lastModified: string;
  owner: string;
  url: string;
}

export interface FileListResponse {
  files: FileInfo[];
  total: number;
  page: number;
  limit: number;
  hasMore: boolean;
}

export interface StorageQuota {
  used: number;
  total: number;
  percentage: number;
} 
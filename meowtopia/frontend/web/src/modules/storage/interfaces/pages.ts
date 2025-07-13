// ============================================================================
// STORAGE PAGES INTERFACES
// ============================================================================

export interface UploadFormData {
  file: File | null;
  description: string;
  tags: string;
  isPublic: boolean;
}

export interface DownloadFormData {
  fileId: string;
  destination: string;
}

export interface ManageFormData {
  fileId: string;
  action: "delete" | "update" | "share" | "rename";
  newName?: string;
  newDescription?: string;
  newTags?: string;
  newIsPublic?: boolean;
}

export interface FileListFormData {
  page: number;
  limit: number;
  search: string;
  filter: "all" | "images" | "documents" | "public" | "private";
  sortBy: "name" | "size" | "date" | "type";
  sortOrder: "asc" | "desc";
}

export interface StorageDashboardData {
  totalFiles: number;
  totalSize: number;
  usedQuota: number;
  availableQuota: number;
  recentFiles: FileListItem[];
  storageStats: StorageStats;
}

export interface StorageStats {
  filesByType: Record<string, number>;
  filesBySize: Record<string, number>;
  uploadsByDay: Record<string, number>;
  downloadsByDay: Record<string, number>;
}

export interface FileListItem {
  id: string;
  name: string;
  size: number;
  type: string;
  uploadedAt: string;
  lastModified: string;
  isPublic: boolean;
  description?: string;
  tags?: string[];
  url: string;
  thumbnailUrl?: string;
}

export interface UploadProgressData {
  fileId: string;
  filename: string;
  progress: number;
  status: "uploading" | "completed" | "error";
  error?: string;
}

export interface DownloadProgressData {
  fileId: string;
  filename: string;
  progress: number;
  status: "downloading" | "completed" | "error";
  error?: string;
} 
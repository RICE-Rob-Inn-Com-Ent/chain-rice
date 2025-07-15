// ============================================================================
// STORAGE API CONFIGURATION
// ============================================================================

import { ApiEndpoint } from "../interfaces/api";

export const storageApiEndpoints: Record<string, ApiEndpoint> = {
  upload: {
    url: "/api/storage/upload",
    method: "POST",
    headers: {},
    timeout: 60000,
    retryAttempts: 3,
  },
  
  download: {
    url: "/api/storage/download",
    method: "GET",
    headers: {},
    timeout: 30000,
    retryAttempts: 3,
  },
  
  list: {
    url: "/api/storage/files",
    method: "GET",
    headers: {},
    timeout: 10000,
    retryAttempts: 2,
  },
  
  delete: {
    url: "/api/storage/files",
    method: "DELETE",
    headers: {},
    timeout: 10000,
    retryAttempts: 2,
  },
  
  update: {
    url: "/api/storage/files",
    method: "PUT",
    headers: {},
    timeout: 15000,
    retryAttempts: 2,
  },
  
  share: {
    url: "/api/storage/share",
    method: "POST",
    headers: {},
    timeout: 10000,
    retryAttempts: 2,
  },
  
  quota: {
    url: "/api/storage/quota",
    method: "GET",
    headers: {},
    timeout: 5000,
    retryAttempts: 1,
  },
  
  search: {
    url: "/api/storage/search",
    method: "GET",
    headers: {},
    timeout: 10000,
    retryAttempts: 2,
  },
};

export const getStorageApiEndpoint = (name: string, params?: Record<string, string>): ApiEndpoint => {
  const endpoint = storageApiEndpoints[name];
  if (!endpoint) {
    throw new Error(`Unknown storage API endpoint: ${name}`);
  }
  
  if (params) {
    const url = new URL(endpoint.url, window.location.origin);
    Object.entries(params).forEach(([key, value]) => {
      url.searchParams.append(key, value);
    });
    return { ...endpoint, url: url.pathname + url.search };
  }
  
  return endpoint;
};

export const storageApiConfig = {
  baseUrl: process.env.REACT_APP_STORAGE_API_URL || "http://localhost:8000",
  version: "v1",
  timeout: 30000,
  retryAttempts: 3,
  headers: {
    "Content-Type": "application/json",
  },
}; 
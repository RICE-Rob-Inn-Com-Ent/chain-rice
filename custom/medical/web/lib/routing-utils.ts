/**
 * Standardized routing utilities for all projects
 * Works with panel.{projekt}.ltd routing pattern
 */

/**
 * Get project domain from environment variables (standardized)
 */
export function getProjectDomain(): string {
  return process.env.PROJECT_DOMAIN || process.env.NEXT_PUBLIC_BASE_URL?.replace(/^https?:\/\//, '') || 'localhost';
}

/**
 * Get panel domain from environment variables (standardized)
 */
export function getPanelDomain(): string {
  return process.env.PROJECT_PANEL_DOMAIN || process.env.NEXT_PUBLIC_PANEL_URL?.replace(/^https?:\/\//, '') || 'panel.localhost';
}

/**
 * Check if current hostname is panel subdomain
 */
export function isPanelSubdomain(hostname?: string): boolean {
  if (typeof window === 'undefined' && !hostname) {
    return false;
  }
  const host = hostname || (typeof window !== 'undefined' ? window.location.hostname : '');
  const panelDomain = getPanelDomain();
  return host === panelDomain || host.startsWith('panel.');
}

/**
 * Get base domain from hostname (removes panel. prefix)
 */
export function getBaseDomainFromHost(hostname?: string): string {
  if (typeof window === 'undefined' && !hostname) {
    return getProjectDomain();
  }
  const host = hostname || (typeof window !== 'undefined' ? window.location.hostname : '');
  if (host.startsWith('panel.')) {
    return host.replace(/^panel\./, '');
  }
  return host;
}

/**
 * Get panel URL for redirect (standardized)
 */
export function getPanelUrl(path: string = ''): string {
  if (typeof window === 'undefined') {
    const protocol = 'http';
    const panelDomain = getPanelDomain();
    return `${protocol}://${panelDomain}${path.startsWith('/') ? path : '/' + path}`;
  }
  const protocol = window.location.protocol;
  const panelDomain = getPanelDomain();
  return `${protocol}//${panelDomain}${path.startsWith('/') ? path : '/' + path}`;
}

/**
 * Get storage public URL (standardized)
 */
export function getStoragePublicUrl(path: string = ''): string {
  const storageUrl = process.env.STORAGE_PUBLIC_URL || process.env.NEXT_PUBLIC_STORAGE_URL || 'http://storage.localhost';
  return `${storageUrl}${path.startsWith('/') ? path : '/' + path}`;
}

/**
 * Get storage base URL (internal)
 */
export function getStorageBaseUrl(): string {
  return process.env.STORAGE_BASE_URL || process.env.MINIO_ENDPOINT || 'http://devcontainer-minio:9000';
}









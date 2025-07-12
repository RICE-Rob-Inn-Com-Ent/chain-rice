// ============================================================================
// API TYPES & INTERFACES (for Auth module)
// ============================================================================

export interface ApiEndpoint {
  url: string;
  method: "GET" | "POST" | "PUT" | "DELETE" | "PATCH";
  headers?: Record<string, string>;
  timeout?: number;
  retryAttempts?: number;
}

export interface SocialProvider {
  name: string;
  icon: string;
  color: string;
  url: string;
  enabled: boolean;
  clientId?: string;
  redirectUri?: string;
}
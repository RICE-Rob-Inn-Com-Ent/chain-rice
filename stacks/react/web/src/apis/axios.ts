import axios, { AxiosError } from 'axios';
import type { AxiosInstance, AxiosResponse } from 'axios';

// Configuration
const API_BASE_URL = 'http://localhost:8003';
const BLOCKCHAIN_BASE_URL = 'http://localhost:1317';

// Create main axios instance
export const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Create blockchain axios instance
export const blockchainClient: AxiosInstance = axios.create({
  baseURL: BLOCKCHAIN_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
apiClient.interceptors.request.use(
  config => {
    console.log(
      `🚀 API Request: ${config.method?.toUpperCase()} ${config.url}`
    );
    return config;
  },
  error => {
    console.error('❌ Request Error:', error);
    return Promise.reject(error);
  }
);

// Response interceptor
apiClient.interceptors.response.use(
  (response: AxiosResponse) => {
    console.log(`✅ API Response: ${response.status} ${response.config.url}`);
    return response;
  },
  (error: AxiosError) => {
    console.error(
      `❌ API Error: ${error.response?.status} ${error.response?.statusText}`
    );
    console.error('Error details:', error.response?.data);
    return Promise.reject(error);
  }
);

// Blockchain request interceptor
blockchainClient.interceptors.request.use(
  config => {
    console.log(
      `🔗 Blockchain Request: ${config.method?.toUpperCase()} ${config.url}`
    );
    return config;
  },
  error => {
    console.error('❌ Blockchain Request Error:', error);
    return Promise.reject(error);
  }
);

// Blockchain response interceptor
blockchainClient.interceptors.response.use(
  (response: AxiosResponse) => {
    console.log(
      `✅ Blockchain Response: ${response.status} ${response.config.url}`
    );
    return response;
  },
  (error: AxiosError) => {
    console.error(
      `❌ Blockchain Error: ${error.response?.status} ${error.response?.statusText}`
    );
    return Promise.reject(error);
  }
);

// Helper function to handle API errors
export const handleApiError = (error: AxiosError): string => {
  if (error.response) {
    // Server responded with error status
    const status = error.response.status;
    const message =
      (error.response.data as any)?.message || error.response.statusText;

    switch (status) {
      case 400:
        return `Błąd walidacji: ${message}`;
      case 401:
        return 'Brak autoryzacji';
      case 403:
        return 'Brak uprawnień';
      case 404:
        return `Endpoint nie znaleziony: ${error.config?.url}`;
      case 500:
        return `Błąd serwera: ${message}`;
      default:
        return `Błąd API (${status}): ${message}`;
    }
  } else if (error.request) {
    // Request was made but no response received
    return 'Brak odpowiedzi z serwera';
  } else {
    // Something else happened
    return `Błąd żądania: ${error.message}`;
  }
};

// Export configuration
export const config = {
  API_BASE_URL,
  BLOCKCHAIN_BASE_URL,
  timeout: 10000,
};

export default apiClient;

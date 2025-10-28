export interface RetryOptions {
  maxAttempts?: number;
  initialDelay?: number;
  maxDelay?: number;
  backoffMultiplier?: number;
}

/**
 * Retry a function with exponential backoff
 */
export async function retryWithBackoff<T>(fn: () => Promise<T>, options: RetryOptions = {}): Promise<T> {
  const { maxAttempts = 3, initialDelay = 1000, maxDelay = 10000, backoffMultiplier = 2 } = options;

  let lastError: Error | null = null;
  let delay = initialDelay;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));

      if (attempt === maxAttempts) {
        throw lastError;
      }

      console.warn(`Attempt ${attempt} failed, retrying in ${delay}ms...`, lastError.message);

      await new Promise((resolve) => setTimeout(resolve, delay));
      delay = Math.min(delay * backoffMultiplier, maxDelay);
    }
  }

  throw lastError || new Error("Retry failed");
}

/**
 * Check if error is a CORS error
 */
export function isCORSError(error: unknown): boolean {
  if (error instanceof TypeError) {
    return error.message.includes("CORS") || error.message.includes("Failed to fetch");
  }
  return false;
}

/**
 * Check if error is a network error
 */
export function isNetworkError(error: unknown): boolean {
  if (error instanceof TypeError) {
    return (
      error.message.includes("Failed to fetch") ||
      error.message.includes("NetworkError") ||
      error.message.includes("Network request failed")
    );
  }
  return false;
}

/**
 * Format error message for display
 */
export function formatErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    if (isCORSError(error)) {
      return "Connection blocked by CORS policy. Please check if the service is running.";
    }
    if (isNetworkError(error)) {
      return "Network error. Please check your connection or if the service is running.";
    }
    return error.message;
  }
  return String(error);
}

/**
 * Log error to console with context
 */
export function logError(context: string, error: unknown): void {
  const message = formatErrorMessage(error);
  console.error(`[${context}]`, message, error);
}

/**
 * Handle async errors with retry and logging
 */
export async function handleAsyncError<T>(
  fn: () => Promise<T>,
  context: string,
  options?: RetryOptions
): Promise<T | null> {
  try {
    return await retryWithBackoff(fn, options);
  } catch (error) {
    logError(context, error);
    return null;
  }
}

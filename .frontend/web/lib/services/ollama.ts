export interface OllamaModel {
  name: string;
  size: number;
  digest: string;
  modified_at: string;
  details?: {
    format: string;
    family: string;
    families: string[];
    parameter_size: string;
    quantization_level: string;
  };
}

export interface ModelStatus {
  loaded: boolean;
  size?: number;
  digest?: string;
}

export interface DownloadProgress {
  status: "pulling" | "complete" | "error";
  completed: number;
  total: number;
  digest?: string;
}

export interface OllamaGenerateResponse {
  model: string;
  response: string;
  done: boolean;
}

const OLLAMA_BASE = "/api/ollama";

/**
 * Get list of all downloaded Ollama models
 */
export async function getOllamaModels(): Promise<OllamaModel[]> {
  try {
    const response = await fetch(`${OLLAMA_BASE}/api/tags`, {
      method: "GET",
      headers: { "Content-Type": "application/json" },
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch models: ${response.status}`);
    }

    const data = await response.json();
    return data.models || [];
  } catch (error) {
    console.error("Failed to get Ollama models:", error);
    throw error;
  }
}

/**
 * Check if a specific model is loaded in memory
 */
export async function getModelStatus(modelName: string): Promise<ModelStatus> {
  try {
    const response = await fetch(`${OLLAMA_BASE}/api/show`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: modelName }),
    });

    if (!response.ok) {
      return { loaded: false };
    }

    const data = await response.json();
    return {
      loaded: true,
      size: data.size,
      digest: data.digest,
    };
  } catch (error) {
    console.error(`Failed to get status for ${modelName}:`, error);
    return { loaded: false };
  }
}

/**
 * Pull/download a model from Ollama registry
 */
export async function pullModel(modelName: string, onProgress?: (progress: DownloadProgress) => void): Promise<void> {
  try {
    const response = await fetch(`${OLLAMA_BASE}/api/pull`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: modelName, stream: true }),
    });

    if (!response.ok) {
      throw new Error(`Failed to pull model: ${response.status}`);
    }

    const reader = response.body?.getReader();
    if (!reader) throw new Error("No response body");

    const decoder = new TextDecoder();
    let buffer = "";

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split("\n");
      buffer = lines.pop() || "";

      for (const line of lines) {
        if (!line.trim()) continue;
        try {
          const data = JSON.parse(line);
          if (onProgress && data.total) {
            onProgress({
              status: data.status === "success" ? "complete" : "pulling",
              completed: data.completed || 0,
              total: data.total || 0,
              digest: data.digest,
            });
          }
        } catch (e) {
          console.warn("Failed to parse progress:", e);
        }
      }
    }
  } catch (error) {
    console.error(`Failed to pull model ${modelName}:`, error);
    throw error;
  }
}

/**
 * Load a model into GPU memory
 */
export async function loadModel(modelName: string): Promise<void> {
  try {
    // Generate a dummy request to load the model
    const response = await fetch(`${OLLAMA_BASE}/api/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: modelName,
        prompt: "",
        stream: false,
      }),
    });

    if (!response.ok) {
      throw new Error(`Failed to load model: ${response.status}`);
    }
  } catch (error) {
    console.error(`Failed to load model ${modelName}:`, error);
    throw error;
  }
}

/**
 * Unload a model from GPU memory (not directly supported by Ollama, but we can try)
 */
export async function unloadModel(modelName: string): Promise<void> {
  // Ollama doesn't have a direct unload API, but we can use the delete endpoint
  // or just let it naturally unload when another model is loaded
  console.log(`Unloading ${modelName} (will happen automatically when another model loads)`);
  // No-op for now, Ollama manages memory automatically
}

/**
 * Delete a model from disk
 */
export async function deleteModel(modelName: string): Promise<void> {
  try {
    const response = await fetch(`${OLLAMA_BASE}/api/delete`, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: modelName }),
    });

    if (!response.ok) {
      throw new Error(`Failed to delete model: ${response.status}`);
    }
  } catch (error) {
    console.error(`Failed to delete model ${modelName}:`, error);
    throw error;
  }
}

/**
 * Check if Ollama is running and accessible
 */
export async function checkOllamaHealth(): Promise<boolean> {
  try {
    const response = await fetch(`${OLLAMA_BASE}/api/tags`, {
      method: "GET",
      headers: { "Content-Type": "application/json" },
    });
    return response.ok;
  } catch (error) {
    return false;
  }
}

/**
 * Get running models (models currently loaded in memory)
 */
export async function getRunningModels(): Promise<string[]> {
  try {
    const response = await fetch(`${OLLAMA_BASE}/api/ps`, {
      method: "GET",
      headers: { "Content-Type": "application/json" },
    });

    if (!response.ok) {
      return [];
    }

    const data = await response.json();
    return data.models?.map((m: any) => m.name) || [];
  } catch (error) {
    console.error("Failed to get running models:", error);
    return [];
  }
}


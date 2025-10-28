import { useState, useEffect, useCallback } from "react";
import {
  OllamaModel,
  DownloadProgress,
  getOllamaModels,
  getRunningModels,
  checkOllamaHealth,
  pullModel,
  loadModel,
} from "../services/ollama";

export interface OllamaState {
  models: OllamaModel[];
  runningModels: string[];
  isHealthy: boolean;
  loading: boolean;
  error: string | null;
  downloadProgress: Map<string, DownloadProgress>;
}

export interface OllamaActions {
  refresh: () => Promise<void>;
  pull: (modelName: string) => Promise<void>;
  load: (modelName: string) => Promise<void>;
}

export function useOllama(pollingInterval = 2000): OllamaState & OllamaActions {
  const [models, setModels] = useState<OllamaModel[]>([]);
  const [runningModels, setRunningModels] = useState<string[]>([]);
  const [isHealthy, setIsHealthy] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [downloadProgress, setDownloadProgress] = useState<Map<string, DownloadProgress>>(new Map());

  const refresh = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const [healthy, modelList, running] = await Promise.all([
        checkOllamaHealth(),
        getOllamaModels().catch(() => []),
        getRunningModels().catch(() => []),
      ]);

      setIsHealthy(healthy);
      setModels(modelList);
      setRunningModels(running);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Failed to fetch Ollama data";
      setError(message);
      setIsHealthy(false);
    } finally {
      setLoading(false);
    }
  }, []);

  const pull = useCallback(
    async (modelName: string) => {
      try {
        setError(null);
        await pullModel(modelName, (progress) => {
          setDownloadProgress((prev) => {
            const next = new Map(prev);
            next.set(modelName, progress);
            return next;
          });
        });
        // Refresh models after pull completes
        await refresh();
        // Clear progress
        setDownloadProgress((prev) => {
          const next = new Map(prev);
          next.delete(modelName);
          return next;
        });
      } catch (err) {
        const message = err instanceof Error ? err.message : `Failed to pull ${modelName}`;
        setError(message);
        throw err;
      }
    },
    [refresh]
  );

  const load = useCallback(
    async (modelName: string) => {
      try {
        setError(null);
        await loadModel(modelName);
        await refresh();
      } catch (err) {
        const message = err instanceof Error ? err.message : `Failed to load ${modelName}`;
        setError(message);
        throw err;
      }
    },
    [refresh]
  );

  // Initial fetch
  useEffect(() => {
    refresh();
  }, [refresh]);

  // Polling
  useEffect(() => {
    if (pollingInterval <= 0) return;

    const interval = setInterval(refresh, pollingInterval);
    return () => clearInterval(interval);
  }, [refresh, pollingInterval]);

  return {
    models,
    runningModels,
    isHealthy,
    loading,
    error,
    downloadProgress,
    refresh,
    pull,
    load,
  };
}

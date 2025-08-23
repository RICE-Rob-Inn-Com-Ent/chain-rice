import { useState, useCallback } from "react";
import { ContainerConfig } from "../interfaces/Container";

export const useContainer = (initialConfig?: Partial<ContainerConfig>) => {
  const [config, setConfig] = useState<ContainerConfig>({
    tag: "div",
    variant: "default",
    ...initialConfig,
  });

  const updateConfig = useCallback((updates: Partial<ContainerConfig>) => {
    setConfig(prev => ({ ...prev, ...updates }));
  }, []);

  const setVariant = useCallback((variant: ContainerConfig["variant"]) => {
    setConfig(prev => ({ ...prev, variant }));
  }, []);

  const setTag = useCallback((tag: ContainerConfig["tag"]) => {
    setConfig(prev => ({ ...prev, tag }));
  }, []);

  const setTableData = useCallback((tableData: any[]) => {
    setConfig(prev => ({ ...prev, tableData }));
  }, []);

  const setLoading = useCallback((loading: boolean) => {
    setConfig(prev => ({ ...prev, loading }));
  }, []);

  const setError = useCallback((error: string | null) => {
    setConfig(prev => ({ ...prev, error }));
  }, []);

  return {
    config,
    updateConfig,
    setVariant,
    setTag,
    setTableData,
    setLoading,
    setError,
  };
};

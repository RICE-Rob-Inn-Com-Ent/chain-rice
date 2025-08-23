import { useState, useCallback } from "react";
import { TextConfig } from "../interfaces/Text";

export const useText = (initialConfig?: Partial<TextConfig>) => {
  const [config, setConfig] = useState<TextConfig>({
    tag: "span",
    variant: "body",
    children: "",
    ...initialConfig,
  });

  const updateConfig = useCallback((updates: Partial<TextConfig>) => {
    setConfig(prev => ({ ...prev, ...updates }));
  }, []);

  const setTag = useCallback((tag: TextConfig["tag"]) => {
    setConfig(prev => ({ ...prev, tag }));
  }, []);

  const setVariant = useCallback((variant: TextConfig["variant"]) => {
    setConfig(prev => ({ ...prev, variant }));
  }, []);

  const setContent = useCallback((children: React.ReactNode) => {
    setConfig(prev => ({ ...prev, children }));
  }, []);

  return {
    config,
    updateConfig,
    setTag,
    setVariant,
    setContent,
  };
};

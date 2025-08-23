import { useState, useCallback } from "react";
import { ClickInterface } from "../interfaces/Click";

export const useClick = (initialConfig?: Partial<Clickinterface>) => {
  const [config, setConfig] = useState<ClickInterface>({
    variant: "button",
    size: "md",
    disabled: false,
    children: "",
    ...initialConfig,
  });

  const [isPressed, setIsPressed] = useState(false);

  const updateConfig = useCallback((updates: Partial<ClickInterface>) => {
    setConfig(prev => ({ ...prev, ...updates }));
  }, []);

  const setVariant = useCallback((variant: ClickInterface["variant"]) => {
    setConfig(prev => ({ ...prev, variant }));
  }, []);

  const setSize = useCallback((size: ClickInterface["size"]) => {
    setConfig(prev => ({ ...prev, size }));
  }, []);

  const setDisabled = useCallback((disabled: boolean) => {
    setConfig(prev => ({ ...prev, disabled }));
  }, []);

  const setChildren = useCallback((children: React.ReactNode) => {
    setConfig(prev => ({ ...prev, children }));
  }, []);

  const handleClick = useCallback(() => {
    if (!config.disabled && config.onClick) {
      setIsPressed(true);
      config.onClick();
      setTimeout(() => setIsPressed(false), 150);
    }
  }, [config.disabled, config.onClick]);

  return {
    config,
    isPressed,
    updateConfig,
    setVariant,
    setSize,
    setDisabled,
    setChildren,
    handleClick,
  };
};

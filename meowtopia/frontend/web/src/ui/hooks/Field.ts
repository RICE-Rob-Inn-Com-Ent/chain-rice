import { useState, useCallback } from "react";
import { FieldConfig } from "../interfaces/Field";

export const useField = (initialConfig?: Partial<FieldConfig>) => {
  const [config, setConfig] = useState<FieldConfig>({
    tag: "input",
    type: "text",
    role: "default",
    size: "md",
    ...initialConfig,
  });

  const [value, setValue] = useState<string>("");
  const [checked, setChecked] = useState<boolean>(false);

  const updateConfig = useCallback((updates: Partial<FieldConfig>) => {
    setConfig(prev => ({ ...prev, ...updates }));
  }, []);

  const setTag = useCallback((tag: FieldConfig["tag"]) => {
    setConfig(prev => ({ ...prev, tag }));
  }, []);

  const setType = useCallback((type: FieldConfig["type"]) => {
    setConfig(prev => ({ ...prev, type }));
  }, []);

  const setRole = useCallback((role: FieldConfig["role"]) => {
    setConfig(prev => ({ ...prev, role }));
  }, []);

  const setSize = useCallback((size: FieldConfig["size"]) => {
    setConfig(prev => ({ ...prev, size }));
  }, []);

  const setIcon = useCallback((icon: string) => {
    setConfig(prev => ({ ...prev, icon }));
  }, []);

  const setPlaceholder = useCallback((placeholder: string) => {
    setConfig(prev => ({ ...prev, placeholder }));
  }, []);

  const handleChange = useCallback((newValue: string | boolean) => {
    if (typeof newValue === "boolean") {
      setChecked(newValue);
    } else {
      setValue(newValue);
    }
  }, []);

  return {
    config,
    value,
    checked,
    updateConfig,
    setTag,
    setType,
    setRole,
    setSize,
    setIcon,
    setPlaceholder,
    handleChange,
  };
};

import React, { createContext, useContext, useMemo } from 'react';

export type BrandConfig = {
  appName?: string;
  logoUrl?: string;
  primaryColor?: string;
  showAuthButtons?: boolean;
  signInLabel?: string;
  signUpLabel?: string;
};

const defaultConfig: Required<BrandConfig> = {
  appName: 'InfiniR',
  logoUrl: '/infinir-logo.png',
  primaryColor: '#2563eb',
  showAuthButtons: true,
  signInLabel: 'Sign In',
  signUpLabel: 'Sign Up',
};

const ConfigContext = createContext<Required<BrandConfig>>(defaultConfig);

export function useUiConfig(): Required<BrandConfig> {
  return useContext(ConfigContext);
}

export function ConfigProvider({ children, value }: { children: React.ReactNode; value?: BrandConfig }) {
  const merged = useMemo(() => ({ ...defaultConfig, ...(value || {}) }), [value]);
  return <ConfigContext.Provider value={merged}>{children}</ConfigContext.Provider>;
}

export default ConfigProvider;

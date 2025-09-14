export type Theme =
  | 'violet-dark'
  | 'violet-light'
  | 'midnight-purple'
  | 'cosmic-violet';

export interface ThemeConfig {
  id: Theme;
  name: string;
  description: string;
  icon: string;
  preview: {
    primary: string;
    secondary: string;
    accent: string;
  };
}

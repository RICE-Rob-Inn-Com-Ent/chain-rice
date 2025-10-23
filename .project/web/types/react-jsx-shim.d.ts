// Minimal shims to satisfy the TypeScript compiler and editor when node_modules types are unavailable.
// NOTE: These are intended only as a fallback for local analysis and should not replace proper @types packages.

declare module 'react' {
  const React: {
    forwardRef<T, P = any>(render: (props: P, ref: any) => any): any;
    Fragment: any;
    useState: <S = any>(initial?: S) => [S, (value: S | ((prev: S) => S)) => void];
    useEffect: (effect: () => void | (() => void), deps?: any[]) => void;
    useMemo: <T = any>(factory: () => T, deps?: any[]) => T;
    useCallback: <T extends (...args: any[]) => any>(callback: T, deps?: any[]) => T;
    useRef: <T = any>(initial?: T | null) => { current: T | null };
    createElement: any;
  };
  export default React;
  export function useState<S = any>(initial?: S): [S, (value: S | ((prev: S) => S)) => void];
  export function useEffect(effect: () => void | (() => void), deps?: any[]): void;
  export function useMemo<T = any>(factory: () => T, deps?: any[]): T;
  export function useCallback<T extends (...args: any[]) => any>(callback: T, deps?: any[]): T;
  export function useRef<T = any>(initial?: T | null): { current: T | null };
}

declare namespace JSX {
  interface IntrinsicElements {
    [elemName: string]: any;
  }
}

// Minimal React namespace to satisfy React.FC usage
declare namespace React {
  type ReactNode = any;
  interface FC<P = any> {
    (props: P & { children?: any }): any;
  }
  interface HTMLAttributes<T = any> {
    [key: string]: any;
  }
  interface ButtonHTMLAttributes<T = any> extends HTMLAttributes<T> {}
  interface InputHTMLAttributes<T = any> extends HTMLAttributes<T> {
    name?: string;
    type?: any;
  }
  interface TextareaHTMLAttributes<T = any> extends HTMLAttributes<T> {
    name?: string;
  }
  interface FormEvent<T = any> {
    target: T;
    currentTarget: T;
    preventDefault(): void;
  }
}

// Next.js ambient modules and types (minimal)
declare module 'next' {
  export type Metadata = any;
  export type Viewport = any;
  export namespace MetadataRoute {
    type Sitemap = any;
    type Robots = any;
    type Manifest = any;
  }
  export type MetadataRoute = typeof MetadataRoute;
  export type NextConfig = any;
  const nextDefault: any;
  export default nextDefault;
}

declare module 'next/link' {
  const Link: any;
  export default Link;
}

declare module 'next/dynamic' {
  const dynamic: any;
  export default dynamic;
}

declare module 'next/font/google' {
  export const Poppins: any;
  export const Orbitron: any;
  export const Inter: any;
}

// Third-party libs used in UI
declare module 'lucide-react' {
  export const Cpu: any;
  export const Cog: any;
  export const Network: any;
  export const Cloud: any;
  export const ShieldCheck: any;
  export const Award: any;
  export const Smartphone: any;
  export const Brain: any;
  export const Blocks: any;
  export const Database: any;
  export const MessageSquare: any;
  export const X: any;
}

declare module 'next/image' {
  const Image: any;
  export default Image;
}

declare module 'tailwindcss' {
  export type Config = any;
}

declare module 'clsx' {
  const clsx: (...args: any[]) => string;
  export default clsx;
}

// Minimal Node-like globals used in code
declare const process: any;

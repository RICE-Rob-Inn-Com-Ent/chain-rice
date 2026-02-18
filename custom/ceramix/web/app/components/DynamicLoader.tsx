'use client';

import { ComponentType, Suspense, lazy, useEffect, useState } from 'react';
import { trackComponentLoad } from './loading-tracker';

interface DynamicLoaderProps<T = {}> {
  importFn: () => Promise<{ default: ComponentType<T> }>;
  componentName: string;
  fallback?: React.ReactNode;
  totalComponents?: number;
  props?: T;
}

/**
 * DynamicLoader component with progress tracking
 * Automatically tracks component loading for progress bar
 */
export default function DynamicLoader<T = {}>({
  importFn,
  componentName,
  fallback,
  totalComponents = 1,
  props,
}: DynamicLoaderProps<T>) {
  const [Component, setComponent] = useState<ComponentType<T> | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;

    const loadComponent = async () => {
      try {
        const module = await importFn();
        if (isMounted) {
          setComponent(() => module.default);
          setIsLoading(false);
          // Track component load
          trackComponentLoad(componentName, totalComponents);
        }
      } catch (error) {
        console.error(`Error loading component ${componentName}:`, error);
        if (isMounted) {
          setIsLoading(false);
        }
      }
    };

    loadComponent();

    return () => {
      isMounted = false;
    };
  }, [importFn, componentName, totalComponents]);

  if (isLoading || !Component) {
    return (
      <Suspense fallback={fallback || <div className="animate-pulse bg-white/5 rounded h-20" />}>
        {fallback || <div className="animate-pulse bg-white/5 rounded h-20" />}
      </Suspense>
    );
  }

  return <Component {...(props as T)} />;
}

/**
 * Helper function to create a lazy-loaded component with tracking
 */
export function createLazyComponent<T = {}>(
  importFn: () => Promise<{ default: ComponentType<T> }>,
  componentName: string,
  totalComponents: number = 1
) {
  const LazyComponent = lazy(importFn);
  
  return function TrackedLazyComponent(props: T) {
    useEffect(() => {
      // Track when component starts loading
      trackComponentLoad(componentName, totalComponents);
    }, []);

    return (
      <Suspense fallback={<div className="animate-pulse bg-white/5 rounded h-20" />}>
        <LazyComponent {...props} />
      </Suspense>
    );
  };
}


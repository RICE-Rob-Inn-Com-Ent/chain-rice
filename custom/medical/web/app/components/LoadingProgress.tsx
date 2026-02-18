'use client';

import { useEffect, useState, useCallback } from 'react';

interface LoadingProgressProps {
  onComplete?: () => void;
}

interface LoadingState {
  components: number;
  componentsLoaded: number;
  database: boolean;
  functions: number;
  functionsLoaded: number;
  totalProgress: number;
}

/**
 * LoadingProgress component tracks and displays loading progress
 * for components, database connections, and function initialization
 */
export default function LoadingProgress({ onComplete }: LoadingProgressProps) {
  const [loadingState, setLoadingState] = useState<LoadingState>({
    components: 0,
    componentsLoaded: 0,
    database: false,
    functions: 0,
    functionsLoaded: 0,
    totalProgress: 0,
  });

  const [isVisible, setIsVisible] = useState(true);

  // Calculate total progress (0-100)
  const calculateProgress = useCallback((state: LoadingState): number => {
    const componentProgress = state.components > 0 
      ? (state.componentsLoaded / state.components) * 40 
      : 0;
    const databaseProgress = state.database ? 30 : 0;
    const functionProgress = state.functions > 0 
      ? (state.functionsLoaded / state.functions) * 30 
      : 0;
    
    return Math.round(componentProgress + databaseProgress + functionProgress);
  }, []);

  // Update loading state
  const updateState = useCallback((updates: Partial<LoadingState>) => {
    setLoadingState((prev) => {
      const newState = { ...prev, ...updates };
      const progress = calculateProgress(newState);
      return { ...newState, totalProgress: progress };
    });
  }, [calculateProgress]);

  // Track component loading
  useEffect(() => {
    // Listen for component load events
    const handleComponentLoad = (event: CustomEvent) => {
      const { componentName, totalComponents } = event.detail;
      setLoadingState((prev) => {
        const newComponents = Math.max(prev.components, totalComponents);
        const newComponentsLoaded = prev.componentsLoaded + 1;
        // Ensure components count is at least equal to loaded count
        const adjustedComponents = Math.max(newComponents, newComponentsLoaded);
        const newState = {
          ...prev,
          components: adjustedComponents,
          componentsLoaded: newComponentsLoaded,
        };
        return {
          ...newState,
          totalProgress: calculateProgress(newState),
        };
      });
    };

    // Listen for database ready event
    const handleDatabaseReady = () => {
      updateState({ database: true });
    };

    // Listen for function initialization
    const handleFunctionInit = (event: CustomEvent) => {
      const { functionName, totalFunctions } = event.detail;
      setLoadingState((prev) => {
        const newFunctions = Math.max(prev.functions, totalFunctions);
        const newFunctionsLoaded = prev.functionsLoaded + 1;
        // Ensure functions count is at least equal to loaded count
        const adjustedFunctions = Math.max(newFunctions, newFunctionsLoaded);
        const newState = {
          ...prev,
          functions: adjustedFunctions,
          functionsLoaded: newFunctionsLoaded,
        };
        return {
          ...newState,
          totalProgress: calculateProgress(newState),
        };
      });
    };

    window.addEventListener('component:load' as any, handleComponentLoad);
    window.addEventListener('database:ready' as any, handleDatabaseReady);
    window.addEventListener('function:init' as any, handleFunctionInit);

    return () => {
      window.removeEventListener('component:load' as any, handleComponentLoad);
      window.removeEventListener('database:ready' as any, handleDatabaseReady);
      window.removeEventListener('function:init' as any, handleFunctionInit);
    };
  }, [updateState]);

  // Check if loading is complete
  useEffect(() => {
    if (loadingState.totalProgress >= 100) {
      // Small delay before hiding to show 100%
      setTimeout(() => {
        setIsVisible(false);
        onComplete?.();
      }, 500);
    }
  }, [loadingState.totalProgress, onComplete]);

  // Auto-hide after timeout to prevent infinite loading
  useEffect(() => {
    const timeout = setTimeout(() => {
      // If progress is at least 90% or database is ready, consider it complete
      if (loadingState.totalProgress >= 90 || loadingState.database) {
        setIsVisible(false);
        onComplete?.();
      }
    }, 5000); // 5 second timeout

    return () => clearTimeout(timeout);
  }, [loadingState.totalProgress, loadingState.database, onComplete]);

  if (!isVisible) {
    return null;
  }

  return (
    <div className="fixed inset-0 z-[9999] bg-obsidian-900/95 backdrop-blur-sm flex items-center justify-center">
      <div className="w-full max-w-md mx-4">
        <div className="bg-obsidian-800/90 border border-white/10 rounded-xl p-6 shadow-2xl">
          {/* Header */}
          <div className="mb-6 text-center">
            <h2 className="text-2xl font-semibold text-ivory-100 mb-2">
              Ładowanie aplikacji
            </h2>
            <p className="text-sm text-ivory-100/60">
              {loadingState.totalProgress}% ukończone
            </p>
          </div>

          {/* Progress Bar */}
          <div className="mb-6">
            <div className="w-full h-3 bg-white/5 rounded-full overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-amber-500 to-ember-500 transition-all duration-300 ease-out rounded-full"
                style={{ width: `${loadingState.totalProgress}%` }}
              />
            </div>
          </div>

          {/* Loading Details */}
          <div className="space-y-3 text-sm">
            {/* Components */}
            <div className="flex items-center justify-between">
              <span className="text-ivory-100/70">Komponenty</span>
              <span className="text-ivory-100 font-medium">
                {loadingState.componentsLoaded} / {loadingState.components || '...'}
              </span>
            </div>

            {/* Database */}
            <div className="flex items-center justify-between">
              <span className="text-ivory-100/70">Baza danych</span>
              <span className="text-ivory-100 font-medium">
                {loadingState.database ? (
                  <span className="text-green-400">✓ Gotowe</span>
                ) : (
                  <span className="text-amber-400">Ładowanie...</span>
                )}
              </span>
            </div>

            {/* Functions */}
            <div className="flex items-center justify-between">
              <span className="text-ivory-100/70">Funkcje</span>
              <span className="text-ivory-100 font-medium">
                {loadingState.functionsLoaded} / {loadingState.functions || '...'}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// Re-export helper functions from separate file for compatibility
export { trackComponentLoad, trackDatabaseReady, trackFunctionInit } from './loading-tracker';


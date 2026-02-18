/**
 * Loading tracker utilities
 * These functions can be used in both server and client components
 * They dispatch events that are handled by the LoadingProgress component
 */

export const trackComponentLoad = (componentName: string, totalComponents: number) => {
  if (typeof window !== 'undefined') {
    window.dispatchEvent(
      new CustomEvent('component:load', {
        detail: { componentName, totalComponents },
      })
    );
  }
};

export const trackDatabaseReady = () => {
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new CustomEvent('database:ready'));
  }
};

export const trackFunctionInit = (functionName: string, totalFunctions: number) => {
  if (typeof window !== 'undefined') {
    window.dispatchEvent(
      new CustomEvent('function:init', {
        detail: { functionName, totalFunctions },
      })
    );
  }
};


'use client';

import { useEffect, useState, useRef } from 'react';
import { usePathname } from 'next/navigation';

interface PageLoaderProps {
  children: React.ReactNode;
}

/**
 * PageLoader component that shows loading indicator during page navigation
 * Only loads the selected page, not the entire application
 */
export default function PageLoader({ children }: PageLoaderProps) {
  const pathname = usePathname();
  const [isLoading, setIsLoading] = useState(false);
  const [progress, setProgress] = useState(0);
  const previousPathRef = useRef<string | null>(null);
  const progressIntervalRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    // Only show loader if pathname actually changed
    if (previousPathRef.current !== null && pathname !== previousPathRef.current) {
      setIsLoading(true);
      setProgress(0);
      
      // Simulate progress with realistic increments
      let currentProgress = 0;
      progressIntervalRef.current = setInterval(() => {
        currentProgress += Math.random() * 15 + 5; // Random increment between 5-20%
        if (currentProgress >= 90) {
          currentProgress = 90;
          if (progressIntervalRef.current) {
            clearInterval(progressIntervalRef.current);
            progressIntervalRef.current = null;
          }
        }
        setProgress(Math.min(currentProgress, 90));
      }, 150);

      // Complete loading after a short delay (simulating page load)
      const timeout = setTimeout(() => {
        if (progressIntervalRef.current) {
          clearInterval(progressIntervalRef.current);
          progressIntervalRef.current = null;
        }
        setProgress(100);
        setTimeout(() => {
          setIsLoading(false);
          setProgress(0);
          previousPathRef.current = pathname;
        }, 200);
      }, 800); // Slightly longer to show the loading state

      return () => {
        if (progressIntervalRef.current) {
          clearInterval(progressIntervalRef.current);
          progressIntervalRef.current = null;
        }
        clearTimeout(timeout);
      };
    } else {
      // First load - set the initial path
      previousPathRef.current = pathname;
    }
  }, [pathname]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (progressIntervalRef.current) {
        clearInterval(progressIntervalRef.current);
      }
    };
  }, []);

  return (
    <>
      {isLoading && (
        <div className="fixed inset-0 z-[9998] bg-obsidian-900/80 backdrop-blur-sm flex items-center justify-center">
          <div className="w-full max-w-md mx-4">
            <div className="bg-obsidian-800/90 border border-white/10 rounded-xl p-6 shadow-2xl">
              {/* Header */}
              <div className="mb-6 text-center">
                <div className="inline-block mb-4">
                  <svg
                    className="animate-spin h-12 w-12 text-amber-500"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      className="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      strokeWidth="4"
                    />
                    <path
                      className="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    />
                  </svg>
                </div>
                <h2 className="text-xl font-semibold text-ivory-100 mb-2">
                  Ładowanie strony
                </h2>
                <p className="text-sm text-ivory-100/60">
                  {Math.round(progress)}% ukończone
                </p>
              </div>

              {/* Progress Bar */}
              <div className="mb-4">
                <div className="w-full h-2 bg-white/5 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-amber-500 to-ember-500 transition-all duration-300 ease-out rounded-full"
                    style={{ width: `${progress}%` }}
                  />
                </div>
              </div>

              {/* Loading Details */}
              <div className="text-sm text-center text-ivory-100/70">
                <p>Ładowanie strony i bazy danych...</p>
              </div>
            </div>
          </div>
        </div>
      )}
      <div className={isLoading ? 'opacity-50 pointer-events-none' : ''}>
        {children}
      </div>
    </>
  );
}


'use client';

import { useEffect, useState } from 'react';
import LoadingProgress from './LoadingProgress';
import { trackDatabaseReady, trackFunctionInit, trackComponentLoad } from './loading-tracker';
import dynamic from 'next/dynamic';

// Lazy load LocationProvider with tracking
const LocationProvider = dynamic(
  () => import('@/app/contexts/LocationContext').then(mod => {
    // Track component load after module is loaded (not during render)
    setTimeout(() => {
      trackComponentLoad('LocationProvider', 10);
    }, 0);
    return { default: mod.LocationProvider };
  }),
  { 
    ssr: false,
    loading: () => {
      // Don't track here - it causes setState during render
      return null;
    },
  }
);

interface AppLoaderProps {
  children: React.ReactNode;
}

/**
 * AppLoader component that wraps the app and tracks loading progress
 */
export default function AppLoader({ children }: AppLoaderProps) {
  useEffect(() => {
    // Track database connection
    const checkDatabase = async () => {
      try {
        // Check if database is ready by making a lightweight health check
        const response = await fetch('/api/health', { 
          method: 'GET',
          cache: 'no-store'
        });
        
        if (response.ok) {
          trackDatabaseReady();
        }
      } catch (error) {
        // Even if health check fails, mark as ready after timeout
        // (database might be ready but health endpoint might not be)
        setTimeout(() => {
          trackDatabaseReady();
        }, 1000);
      }
    };

    // Track function initialization
    const initFunctions = () => {
      const functionsToInit = [
        'auth',
        'location',
        'routing',
        'notifications',
        'analytics',
      ];

      functionsToInit.forEach((funcName, index) => {
        setTimeout(() => {
          trackFunctionInit(funcName, functionsToInit.length);
        }, index * 100);
      });
    };

    checkDatabase();
    initFunctions();
  }, []);

  return (
    <>
      <LoadingProgress />
      <LocationProvider>
        {children}
      </LocationProvider>
    </>
  );
}


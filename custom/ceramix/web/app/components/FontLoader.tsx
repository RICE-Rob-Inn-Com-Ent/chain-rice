'use client';

import { useEffect } from 'react';

/**
 * Client component to load Material Symbols fonts asynchronously
 * This prevents blocking render and reduces console warnings
 */
export default function FontLoader() {
  useEffect(() => {
    // Load Material Symbols fonts asynchronously
    const loadFont = (href: string, id: string) => {
      // Check if already loaded
      if (document.getElementById(id)) {
        return;
      }

      const link = document.createElement('link');
      link.id = id;
      link.rel = 'stylesheet';
      link.href = href;
      link.media = 'print';
      link.onload = () => {
        if (link.media !== 'all') {
          link.media = 'all';
        }
      };
      document.head.appendChild(link);
    };

    // Load fonts with display=swap to prevent render blocking
    loadFont(
      'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=swap',
      'material-symbols-outlined'
    );

    loadFont(
      'https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=swap',
      'material-symbols-rounded'
    );

    loadFont(
      'https://fonts.googleapis.com/css2?family=Material+Symbols+Light:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=swap',
      'material-symbols-light'
    );
  }, []);

  return null;
}




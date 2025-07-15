/**
 * Komponent AdminOnly - Ochrona dostępu tylko dla administratorów
 * 
 * Ten komponent zapewnia kontrolę dostępu na poziomie komponentu,
 * wyświetlając zawartość tylko dla użytkowników z rolą ADMIN.
 * 
 * Funkcjonalności:
 * - Sprawdzanie roli użytkownika
 * - Wyświetlanie komunikatu o braku uprawnień
 * - Możliwość przekierowania na inną stronę
 * - Obsługa stanu ładowania
 * 
 * @author Meowtopia Development Team
 * @version 1.0.0
 */

import React, { ReactNode } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

// ============================================================================
// INTERFEJSY TYPÓW
// ============================================================================

/**
 * Właściwości komponentu AdminOnly
 */
interface AdminOnlyProps {
  /** Komponenty do wyświetlenia dla administratorów */
  children: ReactNode;
  
  /** Komunikat wyświetlany gdy użytkownik nie ma uprawnień */
  fallbackMessage?: string;
  
  /** Ścieżka do przekierowania gdy użytkownik nie ma uprawnień */
  redirectTo?: string;
  
  /** Czy przekierować zamiast wyświetlać komunikat */
  shouldRedirect?: boolean;
  
  /** Klasa CSS dla kontenera komunikatu o braku uprawnień */
  fallbackClassName?: string;
}

// ============================================================================
// KOMPONENT ADMINONLY - Ochrona dostępu dla administratorów
// ============================================================================

/**
 * Komponent AdminOnly
 * Wyświetla zawartość tylko dla użytkowników z rolą ADMIN
 * 
 * @param props - Właściwości komponentu
 * @returns Komponent z zawartością lub komunikatem o braku uprawnień
 */
const AdminOnly: React.FC<AdminOnlyProps> = ({
  children,
  fallbackMessage = "Nie masz uprawnień do przeglądania tej strony. Dostęp tylko dla administratorów.",
  redirectTo = "/",
  shouldRedirect = false,
  fallbackClassName = "flex items-center justify-center min-h-screen bg-gray-50"
}) => {
  // ============================================================================
  // HOOKI - Pobieranie danych z kontekstu autoryzacji
  // ============================================================================
  
  /**
   * Kontekst autoryzacji - dostęp do informacji o użytkowniku
   */
  const { isAuthenticated, isAdmin, loading } = useAuth();

  // ============================================================================
  // LOGIKA KONTROLI DOSTĘPU - Sprawdzanie uprawnień
  // ============================================================================

  /**
   * Sprawdzenie czy użytkownik jest zalogowany i ma rolę administratora
   */
  const hasAdminAccess = isAuthenticated && isAdmin();

  // ============================================================================
  // STANY ŁADOWANIA - Obsługa stanu inicjalizacji
  // ============================================================================

  /**
   * Wyświetlanie stanu ładowania podczas sprawdzania autoryzacji
   */
  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Sprawdzanie uprawnień...</p>
        </div>
      </div>
    );
  }

  // ============================================================================
  // PRZEKIEROWANIE - Obsługa przekierowania dla nieautoryzowanych
  // ============================================================================

  /**
   * Przekierowanie na stronę logowania jeśli użytkownik nie jest zalogowany
   */
  if (!isAuthenticated) {
    return <Navigate to="/auth/login" replace />;
  }

  // ============================================================================
  // KONTROLA DOSTĘPU - Sprawdzanie roli administratora
  // ============================================================================

  /**
   * Przekierowanie lub wyświetlenie komunikatu o braku uprawnień
   */
  if (!hasAdminAccess) {
    if (shouldRedirect) {
      return <Navigate to={redirectTo} replace />;
    }

    return (
      <div className={fallbackClassName}>
        <div className="text-center max-w-md mx-auto p-6">
          <div className="mb-4">
            <svg 
              className="mx-auto h-16 w-16 text-red-500" 
              fill="none" 
              viewBox="0 0 24 24" 
              stroke="currentColor"
            >
              <path 
                strokeLinecap="round" 
                strokeLinejoin="round" 
                strokeWidth={2} 
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" 
              />
            </svg>
          </div>
          <h2 className="text-xl font-semibold text-gray-900 mb-2">
            Brak uprawnień
          </h2>
          <p className="text-gray-600 mb-4">
            {fallbackMessage}
          </p>
          <button
            onClick={() => window.history.back()}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            Wróć
          </button>
        </div>
      </div>
    );
  }

  // ============================================================================
  // WYŚWIETLANIE ZAWARTOŚCI - Dostęp przyznany
  // ============================================================================

  /**
   * Wyświetlenie chronionej zawartości dla administratorów
   */
  return <>{children}</>;
};

export default AdminOnly; 
/**
 * Kontekst Autoryzacji - Zarządzanie stanem uwierzytelniania użytkowników
 * 
 * Ten kontekst zapewnia globalny dostęp do informacji o użytkowniku,
 * jego roli oraz funkcji pomocniczych do sprawdzania uprawnień.
 * 
 * Funkcjonalności:
 * - Zarządzanie stanem uwierzytelniania
 * - Sprawdzanie roli użytkownika (ADMIN/USER)
 * - Automatyczne odświeżanie tokenów
 * - Bezpieczne wylogowywanie
 * 
 * @author Meowtopia Development Team
 * @version 1.0.0
 */

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { getStoredToken, removeStoredToken, isTokenExpired } from '../modules/auth/utils';

// ============================================================================
// INTERFEJSY TYPÓW
// ============================================================================

/**
 * Interfejs użytkownika z informacjami o roli
 */
export interface User {
  id: string;
  email: string;
  fullName: string;
  role: "USER" | "ADMIN";
  avatar?: string;
  emailVerified: boolean;
  createdAt: string;
  lastLogin?: string;
}

/**
 * Stan kontekstu autoryzacji
 */
interface AuthState {
  isAuthenticated: boolean;
  user: User | null;
  loading: boolean;
  error: string | null;
}

/**
 * Funkcje kontekstu autoryzacji
 */
interface AuthContextType extends AuthState {
  login: (user: User) => void;
  logout: () => void;
  isAdmin: () => boolean;
  isUser: () => boolean;
  hasRole: (role: "USER" | "ADMIN") => boolean;
  updateUser: (user: Partial<User>) => void;
}

// ============================================================================
// KONTEKST AUTORYZACJI
// ============================================================================

/**
 * Kontekst autoryzacji - domyślne wartości
 */
const AuthContext = createContext<AuthContextType | undefined>(undefined);

/**
 * Właściwości providera kontekstu autoryzacji
 */
interface AuthProviderProps {
  children: ReactNode;
}

/**
 * Provider kontekstu autoryzacji
 * Zapewnia globalny dostęp do funkcji autoryzacji w całej aplikacji
 */
export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  // ============================================================================
  // STAN KONTEKSTU - Zarządzanie stanem uwierzytelniania
  // ============================================================================
  
  /**
   * Stan uwierzytelniania użytkownika
   */
  const [authState, setAuthState] = useState<AuthState>({
    isAuthenticated: false,
    user: null,
    loading: true,
    error: null,
  });

  // ============================================================================
  // INICJALIZACJA - Sprawdzanie tokenu przy starcie aplikacji
  // ============================================================================

  /**
   * Inicjalizacja stanu autoryzacji przy starcie aplikacji
   * Sprawdza czy istnieje ważny token w localStorage
   */
  useEffect(() => {
    const initializeAuth = async () => {
      try {
        const token = getStoredToken();
        
        if (token && !isTokenExpired(token)) {
          // Token istnieje i jest ważny - pobierz dane użytkownika
          await fetchUserData(token);
        } else if (token && isTokenExpired(token)) {
          // Token wygasł - usuń go
          removeStoredToken();
        }
      } catch (error) {
        console.error('Błąd inicjalizacji autoryzacji:', error);
        removeStoredToken();
      } finally {
        setAuthState(prev => ({ ...prev, loading: false }));
      }
    };

    initializeAuth();
  }, []);

  // ============================================================================
  // FUNKCJE POMOCNICZE - Operacje na danych użytkownika
  // ============================================================================

  /**
   * Pobieranie danych użytkownika z API
   * @param token - Token dostępu
   */
  const fetchUserData = async (token: string) => {
    try {
      const response = await fetch('/api/v1/auth/profile', {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const userData: User = await response.json();
        setAuthState({
          isAuthenticated: true,
          user: userData,
          loading: false,
          error: null,
        });
      } else {
        throw new Error('Nie udało się pobrać danych użytkownika');
      }
    } catch (error) {
      console.error('Błąd pobierania danych użytkownika:', error);
      removeStoredToken();
      setAuthState({
        isAuthenticated: false,
        user: null,
        loading: false,
        error: 'Błąd uwierzytelniania',
      });
    }
  };

  // ============================================================================
  // FUNKCJE KONTEKSTU - Publiczne API kontekstu
  // ============================================================================

  /**
   * Logowanie użytkownika
   * @param user - Dane użytkownika do zalogowania
   */
  const login = (user: User) => {
    setAuthState({
      isAuthenticated: true,
      user,
      loading: false,
      error: null,
    });
  };

  /**
   * Wylogowanie użytkownika
   * Czyści tokeny i resetuje stan autoryzacji
   */
  const logout = () => {
    removeStoredToken();
    setAuthState({
      isAuthenticated: false,
      user: null,
      loading: false,
      error: null,
    });
  };

  /**
   * Sprawdzenie czy użytkownik jest administratorem
   * @returns true jeśli użytkownik ma rolę ADMIN
   */
  const isAdmin = (): boolean => {
    return authState.user?.role === "ADMIN";
  };

  /**
   * Sprawdzenie czy użytkownik jest zwykłym użytkownikiem
   * @returns true jeśli użytkownik ma rolę USER
   */
  const isUser = (): boolean => {
    return authState.user?.role === "USER";
  };

  /**
   * Sprawdzenie czy użytkownik ma określoną rolę
   * @param role - Rola do sprawdzenia (USER lub ADMIN)
   * @returns true jeśli użytkownik ma podaną rolę
   */
  const hasRole = (role: "USER" | "ADMIN"): boolean => {
    return authState.user?.role === role;
  };

  /**
   * Aktualizacja danych użytkownika
   * @param userData - Częściowe dane użytkownika do aktualizacji
   */
  const updateUser = (userData: Partial<User>) => {
    if (authState.user) {
      setAuthState(prev => ({
        ...prev,
        user: { ...prev.user!, ...userData },
      }));
    }
  };

  // ============================================================================
  // WARTOŚCI KONTEKSTU - Kombinacja stanu i funkcji
  // ============================================================================

  const contextValue: AuthContextType = {
    ...authState,
    login,
    logout,
    isAdmin,
    isUser,
    hasRole,
    updateUser,
  };

  return (
    <AuthContext.Provider value={contextValue}>
      {children}
    </AuthContext.Provider>
  );
};

// ============================================================================
// HOOK KONTEKSTU - Łatwy dostęp do kontekstu autoryzacji
// ============================================================================

/**
 * Hook do korzystania z kontekstu autoryzacji
 * @returns Kontekst autoryzacji
 * @throws Error jeśli hook jest używany poza AuthProvider
 */
export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth musi być używany wewnątrz AuthProvider');
  }
  return context;
};

export default AuthContext; 
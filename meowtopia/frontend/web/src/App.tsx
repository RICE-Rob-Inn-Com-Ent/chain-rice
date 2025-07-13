import React, { Suspense, useEffect, useState, lazy } from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";

// Import auth configuration
import { authSettings, passwordPolicy } from "./modules/auth/configs/general";
import { authPageMessages } from "./modules/auth/configs/pages";

// Import authentication context
import { AuthProvider } from "./contexts/AuthContext";

// ============================================================================
// GLOBAL APP CONFIGURATION
// ============================================================================

interface RouteInterface {
  path: string;
  label: string;
  slug: string;
  element: React.ReactNode;
  icon?: React.ReactNode;
  children?: RouteInterface[];
}

interface AppConfig {
  // App Identity
  name: string;
  logo: string;
  theme: "light" | "dark" | "auto";

  // Global UI Configuration
  ui: {
    language: string;
    dateFormat: string;
    timeFormat: string;
    currency: string;
    showPasswordStrength: boolean;
    showSocialLogin: boolean;
    showRememberMe: boolean;
    showMarketingOptIn: boolean;
  };

  // App Styles
  styles: {
    container: string;
    loading: string;
    error: string;
  };

  // App Messages
  messages: {
    loading: string;
    error: string;
  };

  // Routing Configuration
  routes: RouteInterface[];
  fallbackRoute: string;
}

const appConfig: AppConfig = {
  // App Identity
  name: "Meowtopia",
  logo: "/img/logos/chc-logo-color.png",
  theme: "light",

  // Global UI Configuration
  ui: {
    language: "pl",
    dateFormat: "DD/MM/YYYY",
    timeFormat: "HH:mm",
    currency: "PLN",
    showPasswordStrength: authSettings.enableTwoFactor,
    showSocialLogin: authSettings.enableSocialLogin,
    showRememberMe: authSettings.enableRememberMe,
    showMarketingOptIn: false,
  },

  // App Styles
  styles: {
    container: "flex items-center justify-center min-h-screen min-w-screen",
    loading: "p-8 text-center text-lg",
    error: "p-4 text-center text-red-600",
  },

  // App Messages - Using auth configuration for consistency
  messages: {
    loading: authPageMessages.common.loading,
    error: authPageMessages.common.error,
  },

  // Routing Configuration
  routes: [
    {
      path: "/docs/*",
      label: "Docs",
      slug: "docs",
      element: null, // Will be set dynamically
    },
    {
      path: "/auth/*",
      label: "Auth",
      slug: "auth",
      element: null, // Will be set dynamically
    },
    {
      path: "/accounting/*",
      label: "Accounting",
      slug: "accounting",
      element: null, // Will be set dynamically
    },
    {
      path: "/admin",
      label: "Admin",
      slug: "admin",
      element: null, // Will be set dynamically
    },
    {
      path: "/user",
      label: "User",
      slug: "user",
      element: null, // Will be set dynamically
    },
  ],
  fallbackRoute: "/auth",
};

// --- Lazy-loaded pages ---
const Auth = lazy(() => import("./modules/auth/Auth"));
const Docs = lazy(() => import("./modules/docs/Docs"));
const CookiesBanner = lazy(() => import("./components/CookiesBanner"));
const Accounting = lazy(() => import("./modules/accounting/Accounting"));
// Placeholder components for Admin and User
const Admin: React.FC = () => <div>Admin Page (Coming Soon)</div>;
const User: React.FC = () => <div>User Page (Coming Soon)</div>;

// --- Set route elements dynamically ---
const routesWithElements = appConfig.routes.map((route: RouteInterface) => ({
  ...route,
  element:
    route.slug === "docs" ? (
      <Docs />
    ) : route.slug === "auth" ? (
      <Auth />
    ) : route.slug === "accounting" ? (
      <Accounting />
    ) : route.slug === "admin" ? (
      <Admin />
    ) : route.slug === "user" ? (
      <User />
    ) : null,
}));

// --- Render routes recursively ---
function renderRoutes(routes: RouteInterface[]): React.ReactNode[] {
  return routes.map((route) =>
    route.children ? (
      <Route key={route.path} path={route.path} element={route.element}>
        {renderRoutes(route.children)}
      </Route>
    ) : (
      <Route key={route.path} path={route.path} element={route.element} />
    )
  );
}

const App: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [authenticated, setAuthenticated] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem("access_token");
    setAuthenticated(!!token);
    setLoading(false);
  }, []);

  return (
    <AuthProvider>
      <BrowserRouter>
        <Suspense
          fallback={
            <div className={appConfig.styles.container}>
              <div className={appConfig.styles.loading}>
                {appConfig.messages.loading}
              </div>
            </div>
          }
        >
          <CookiesBanner />
          {loading ? (
            <div className={appConfig.styles.container}>
              <div className={appConfig.styles.loading}>
                {appConfig.messages.loading}
              </div>
            </div>
          ) : !authenticated ? (
            <Routes>
              <Route path="/auth/*" element={<Auth />} />
              <Route path="*" element={<Navigate to="/auth/login" replace />} />
            </Routes>
          ) : (
            <Routes>
              {renderRoutes(routesWithElements)}
              <Route
                path="*"
                element={<Navigate to={appConfig.fallbackRoute} replace />}
              />
            </Routes>
          )}
        </Suspense>
      </BrowserRouter>
    </AuthProvider>
  );
};

export default App;

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

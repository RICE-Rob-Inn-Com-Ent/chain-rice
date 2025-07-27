import ReactDOM from "react-dom/client";
import React, { Suspense, useEffect, useState, lazy } from "react";
import { BrowserRouter } from "react-router-dom";
import "./tailwind.css";
import { Container as LoadingContainer } from "./components/Container";
import { Text as LoadingComponent } from "./components/Text";

// Modules lazy
const Docs = lazy(() => import("./modules/docs/Docs"));
const Auth = lazy(() => import("./modules/auth/Auth"));


// Main lazy
const Admin = lazy(() =>
  import("./main/Admin").then((main) => ({ default: main.Admin }))
);
const User = lazy(() =>
  import("./main/User").then((main) => ({ default: main.User }))
);

// Layouts lazy
const Cookies = lazy(() =>
  import("./layouts/Cookies").then((layout) => ({
    default: layout.Cookies,
  }))
);
const Nav = lazy(() =>
  import("./layouts/Nav").then((layout) => ({ default: layout.Nav }))
);

// Loading component using Text
const LoadingText: React.FC = () => (
  <LoadingContainer tag="div" variant="default">
    <LoadingComponent tag="p" variant="body">
      Loading...
    </LoadingComponent>
  </LoadingContainer>
);

const config = {
  appConfig: {
    enableStrictMode: true,
    enableDevTools: process.env.NODE_ENV === "development",
    theme: "light" as const,
    language: "pl" as const,
  },
  routerConfig: {
    basename: "/",
    hashType: "slash",
    window: window,
  },
  suspenseConfig: {
    fallback: undefined as React.ReactNode,
  },
  authConfig: {
    containerClassName: "auth-container",
    redirectAfterLogin: "/admin",
    enableRememberMe: true,
  },
  adminConfig: {
    containerClassName: "admin-container",
    enableNotifications: true,
    defaultRoute: "/dashboard",
  },
};

const App: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [authenticated, setAuthenticated] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem("access_token");
    setAuthenticated(!!token);
    setLoading(false);
  }, []);

  return (
    <BrowserRouter {...config.routerConfig}>
      {/* Main application Suspense with large component loader */}
      <Suspense fallback={<LoadingText />}>
        {loading ? (
          <LoadingText />
        ) : !authenticated ? (
          // Auth module with medium component loader
          <Suspense fallback={<LoadingText />}>
            <Auth />
          </Suspense>
        ) : (
          // Admin module with nested Suspense for different components
          <Suspense fallback={<LoadingText />}>
            <Nav />
            <Admin />
            <Suspense fallback={<LoadingText />}>
              <Cookies />
            </Suspense>
          </Suspense>
        )}
      </Suspense>
    </BrowserRouter>
  );
};

export default App;

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

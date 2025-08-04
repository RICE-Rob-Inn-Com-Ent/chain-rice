import ReactDOM from "react-dom/client";
import React, { Suspense, useEffect, useState, lazy } from "react";
import { BrowserRouter } from "react-router-dom";
import axios from "axios";
import "./tailwind.css";
import { Container, ContainerConfig } from "./components/Container";
import { Text, TextConfig } from "./components/Text";

const Auth = lazy(() => import("./modules/auth/Auth"));

const Admin = lazy(() =>
  import("./main/Admin").then((main) => ({ default: main.Admin }))
);
const User = lazy(() =>
  import("./main/User").then((main) => ({ default: main.User }))
);

const Cookies = lazy(() =>
  import("./layouts/Cookies").then((layout) => ({
    default: layout.Cookies,
  }))
);
const Nav = lazy(() =>
  import("./layouts/Nav").then((layout) => ({ default: layout.Nav }))
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
    tag: "span",
    variant: "body",
    children: "Loading...",
  } as TextConfig,
  authConfig: {
    containerClassName: "auth-container",
    redirectAfterLogin: "/admin",
    enableRememberMe: true,
  },
  mainConfig: {
    tag: "main",
    variant: "default",
  } as ContainerConfig,
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

    if (token) {
      axios.defaults.headers.common["Authorization"] = `Bearer ${token}`;
    }

    setAuthenticated(!!token);
    setLoading(false);
  }, []);

  return (
    <BrowserRouter {...config.routerConfig}>
      <Suspense fallback={<Text {...config.suspenseConfig} />}>
        {loading ? (
          <Text {...config.suspenseConfig} />
        ) : !authenticated ? (
          <Suspense fallback={<Text {...config.suspenseConfig} />}>
            <Auth />
          </Suspense>
        ) : (
          <Suspense fallback={<Text {...config.suspenseConfig} />}>
            <Container {...config.mainConfig}>
              <Nav variant={authenticated ? "admin" : "user"} />
              <Admin />
            </Container>
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

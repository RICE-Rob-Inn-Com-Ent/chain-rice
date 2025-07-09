import React, { Suspense } from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";

import { RouteInterface } from "@/types/interfaces/RouteInterface";
import { appRoutes } from "@/types/routes/routes";
import { useSession } from "@/layouts/modules/Cookies";
import Auth from "@/pages/Auth";

import "@/layouts/styles/tailwind.css";
import { mainStyles } from "@/layouts/styles/mainStyles";

function renderRoutes(routes: RouteInterface[]) {
  return routes.map((route: RouteInterface) => {
    if (route.children) {
      return (
        <Route key={route.path} path={route.path} element={route.element}>
          {renderRoutes(route.children)}
        </Route>
      );
    }
    return <Route key={route.path} path={route.path} element={route.element} />;
  });
}

const App: React.FC = () => {
  const { loading, authenticated } = useSession();

  if (loading) {
    return (
      <div className={mainStyles.container}>
        <div className="p-8 text-center">Loading...</div>
      </div>
    );
  }

  if (!authenticated) {
    return <Auth />;
  }

  return (
    <BrowserRouter>
      <Routes>
        {renderRoutes(appRoutes)}
        <Route path="*" element={<Navigate to="/auth/login" replace />} />
      </Routes>
    </BrowserRouter>
  );
};

export default App;

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

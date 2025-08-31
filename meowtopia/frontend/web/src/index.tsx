import ReactDOM from "react-dom/client";
import React, { lazy } from "react";
import { Routes, Route, BrowserRouter } from "react-router-dom";
import "../tailwind.css";

const Admin = lazy(() => import("./elements/admin/index"));
const Auth = lazy(() => import("./elements/auth/index"));
const Main = lazy(() => import("./elements/main/index"));

const App = () => {
  return (
    <React.StrictMode>
      <BrowserRouter>
        <Routes>
          <Route path="/admin" element={<Admin />} />
          <Route path="/main" element={<Main />} />
          <Route path="/*" element={<Auth />} />
        </Routes>
      </BrowserRouter>
    </React.StrictMode>
  );
};

let root: ReactDOM.Root | null = null;

const initializeApp = () => {
  const container = document.getElementById("root");
  if (container && !root) {
    root = ReactDOM.createRoot(container);
    root.render(<App />);
  }
};

initializeApp();

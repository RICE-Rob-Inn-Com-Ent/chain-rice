import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";
import { ConfigProvider } from "@rice-mono/next-components";
import appConfig from "./app.config";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <ConfigProvider value={appConfig}>
      <App />
    </ConfigProvider>
  </React.StrictMode>
);

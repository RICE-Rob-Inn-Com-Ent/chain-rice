import React from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./app/App";

// Main entry point - renders the App component with all dashboard features
const root = document.getElementById("root");
if (!root) throw new Error("Root element not found");

createRoot(root).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

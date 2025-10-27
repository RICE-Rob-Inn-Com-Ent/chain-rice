import React from "react";
import { createRoot } from "react-dom/client";
import Header from "./molecules/Header";
import "./index.css";

function App() {
  return <Header />;
}

export default App;

const rootEl = document.getElementById("root");
if (!rootEl) throw new Error("Root element not found");

createRoot(rootEl).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

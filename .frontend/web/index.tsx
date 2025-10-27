import React from "react";
import Header from "./lib/molecules/Header";

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

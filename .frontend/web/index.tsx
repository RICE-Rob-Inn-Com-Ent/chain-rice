import React from "react";
import { createRoot } from "react-dom/client";
import Header from "./molecules/Header";
import Footer from "./molecules/Footer";
import "./index.css";

function App({ children }: { children: React.ReactNode } & React.HTMLAttributes<HTMLMainElement>) {
  const { className, ...props } = props;
  return <main className={className} {...props}>
    <>
      <Header />
      {children}
      <Footer />
    </>
  </main>;
}

export default App;

const root = document.getElementById("root");
if (!root) throw new Error("Root element not found");

createRoot(root).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

import React from "react";
import { createRoot } from "react-dom/client";
import Header from "./molecules/Header";
import Footer from "./molecules/Footer";
import "./index.css";

function App() {
  return (
    <>
      <Header />
      <main>
        <HomePage />
        <AboutPage />
        <ServicesPage />
        <TeamPage />
        <ContactPage />
      </main>
      <Footer />
    </>
  );
}

export default App;

const root = document.getElementById("root");
if (!root) throw new Error("Root element not found");

createRoot(root).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

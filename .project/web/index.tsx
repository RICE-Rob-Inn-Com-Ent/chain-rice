import React from "react";
import { createRoot } from "react-dom/client";
import "./styles.css";
import { Header } from "@rice-mono/ui-kit/lib";
import HomePage from "./app/pages/Home";
import AboutPage from "./app/pages/About";
import ServicesPage from "./app/pages/Service";
import TeamPage from "./app/pages/TeamPage";
import ContactPage from "./app/pages/Contact";

function App() {
  return (
    <Header>
      <HomePage />
      <AboutPage />
      <ServicesPage />
      <TeamPage />
      <ContactPage />
    </Header>
  );
}

const rootEl = document.getElementById("root")!;
createRoot(rootEl).render(<App />);

if (import.meta && (import.meta as any).hot) {
  (import.meta as any).hot.accept();
}

import React from "react";
import { Header } from "@rice/ui-kit/lib";
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

export default App;

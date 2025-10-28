"use client";

import { Header } from "@rice-mono/ui-kit/lib";
import HomePage from "./pages/Home";
import AboutPage from "./pages/About";
import ServicePage from "./pages/Service";
import ContactPage from "./pages/Contact";
import PricingPage from "./pages/Pricing";

export default function Page() {
  return (
    <Header>
      <HomePage />
      <AboutPage />
      <ServicePage />
      <ContactPage />
      <PricingPage />
    </Header>
  );
}

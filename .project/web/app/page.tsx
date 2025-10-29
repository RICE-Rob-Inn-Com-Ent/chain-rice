"use client";

import dynamic from "next/dynamic";
import { Header } from "@rice-mono/ui-kit/lib";

// Dynamic imports with SSR disabled for components that use browser APIs or fetch data
const HomePage = dynamic(() => import("./pages/Home"), { ssr: false });
const AboutPage = dynamic(() => import("./pages/About"), { ssr: false });
const ServicePage = dynamic(() => import("./pages/Service"), { ssr: false });
const ContactPage = dynamic(() => import("./pages/Contact"), { ssr: false });
const PricingPage = dynamic(() => import("./pages/Pricing"), { ssr: false });

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

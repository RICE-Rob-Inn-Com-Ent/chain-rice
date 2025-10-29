"use client";

import dynamic from "next/dynamic";

// Loading component
const PageLoader = () => (
  <div className="flex items-center justify-center min-h-screen bg-black">
    <div className="text-white text-xl">Loading...</div>
  </div>
);

// Dynamic imports with SSR disabled for components that use browser APIs or fetch data
const HomePage = dynamic(() => import("./pages/Home"), { ssr: false, loading: () => <PageLoader /> });
const AboutPage = dynamic(() => import("./pages/About"), { ssr: false, loading: () => <PageLoader /> });
const ServicePage = dynamic(() => import("./pages/Service"), { ssr: false, loading: () => <PageLoader /> });
const ContactPage = dynamic(() => import("./pages/Contact"), { ssr: false, loading: () => <PageLoader /> });
const PricingPage = dynamic(() => import("./pages/Pricing"), { ssr: false, loading: () => <PageLoader /> });

export default function Page() {
  return (
    <div className="flex min-h-screen flex-col">
      <main className="flex-1">
        <HomePage />
        <AboutPage />
        <ServicePage />
        <ContactPage />
        <PricingPage />
      </main>
    </div>
  );
}

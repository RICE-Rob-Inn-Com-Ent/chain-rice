import React, { useState } from "react";
import { Layout } from "./Layout";
import { Dashboard } from "./Dashboard";
import { Models } from "./Models";
import { LoRaTraining } from "./LoRaTraining";
import { Prices } from "./Prices";
import { ComponentLibrary } from "./ComponentLibrary";
import { ThemeProvider } from "../lib/contexts/ThemeContext";
import { ErrorBoundary } from "../lib/components/ErrorBoundary";

export type Page = "dashboard" | "models" | "lora" | "prices" | "components";

const App: React.FC = () => {
  const [currentPage, setCurrentPage] = useState<Page>("dashboard");

  const renderPage = () => {
    switch (currentPage) {
      case "dashboard":
        return <Dashboard />;
      case "models":
        return <Models />;
      case "lora":
        return <LoRaTraining />;
      case "prices":
        return <Prices />;
      case "components":
        return <ComponentLibrary />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <ErrorBoundary>
      <ThemeProvider>
        <Layout currentPage={currentPage} onNavigate={(page) => setCurrentPage(page as Page)}>
          {renderPage()}
        </Layout>
      </ThemeProvider>
    </ErrorBoundary>
  );
};

export default App;


import React, { useState } from "react";
import { Layout } from "./Layout";
import { Dashboard } from "./Dashboard";
import { ComponentLibrary } from "./ComponentLibrary";
import { GiPT1Training } from "./GiPT1Training";
import { ThemeProvider } from "../lib/contexts/ThemeContext";
import { ErrorBoundary } from "../lib/components/ErrorBoundary";

export type Page = "dashboard" | "gipt1-training" | "components";

const App: React.FC = () => {
  const [currentPage, setCurrentPage] = useState<Page>("dashboard");

  const renderPage = () => {
    switch (currentPage) {
      case "dashboard":
        return <Dashboard />;
      case "gipt1-training":
        return <GiPT1Training />;
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

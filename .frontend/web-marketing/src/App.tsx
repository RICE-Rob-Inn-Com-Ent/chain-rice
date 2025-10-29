import React from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { ThemeProvider } from "@rice-mono/ui-kit";
import { Layout } from "./Layout";
import { Home } from "./pages/Home";
import { Prices } from "./pages/Prices";
import { About } from "./pages/About";
import { Demo } from "./pages/Demo";
import { Contact } from "./pages/Contact";

const App: React.FC = () => {
  return (
    <ThemeProvider>
      <BrowserRouter>
        <Layout>
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/pricing" element={<Prices />} />
            <Route path="/about" element={<About />} />
            <Route path="/demo" element={<Demo />} />
            <Route path="/contact" element={<Contact />} />
          </Routes>
        </Layout>
      </BrowserRouter>
    </ThemeProvider>
  );
};

export default App;


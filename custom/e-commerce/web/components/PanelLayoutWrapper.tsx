"use client";

import { useEffect, useState } from "react";

export function PanelLayoutWrapper({ children }: { children: React.ReactNode }) {
  const [isPanel, setIsPanel] = useState(false);

  useEffect(() => {
    const hostname = window.location.hostname;
    setIsPanel(hostname.startsWith("panel.") || hostname === "panel.meowtopia.ltd");
  }, []);

  // If on panel subdomain, render without Header/Footer wrapper
  if (isPanel) {
    return <>{children}</>;
  }

  // Regular layout with Header and Footer
  return <>{children}</>;
}











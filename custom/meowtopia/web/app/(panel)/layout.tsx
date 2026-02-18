import type { Metadata } from "next";

export const metadata: Metadata = {
  title: {
    default: "Panel ERP - MeoWTopia",
    template: "%s | Panel ERP - MeoWTopia",
  },
};

// This layout is ONLY for panel routes - no Header/Footer
// NOTE: Do NOT include <html> or <body> tags here - those are in the root layout
// Nested layouts in Next.js App Router should only wrap children, not create new HTML structure
export default function PanelRootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}


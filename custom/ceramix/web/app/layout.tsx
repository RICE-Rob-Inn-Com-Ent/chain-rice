import type { Metadata } from "next";
import { Inter, Playfair_Display } from "next/font/google";
import "./globals.css";
import AppLoader from "./components/AppLoader";

const inter = Inter({ 
  subsets: ["latin", "latin-ext"],
  display: 'swap', // Optimize font loading
  preload: true, // Preload fonts
});

const playfair = Playfair_Display({ 
  subsets: ["latin", "latin-ext"], 
  variable: "--font-display",
  display: 'swap', // Optimize font loading
  preload: true, // Preload fonts
});

export const metadata: Metadata = {
  title: "Ceramix - Klinika Stomatologiczna Bielsko-Biała",
  description: "Profesjonalna opieka stomatologiczna. Protetyka, implanty, wybielanie zębów. Umów wizytę już dziś!",
};

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // CSRF token is now handled in middleware - no need to set it here
  // Setting cookies in Server Components is not allowed in Next.js App Router

  return (
    <html lang="pl" className={`${inter.className} ${playfair.variable}`}>
      <head>
        <link rel="manifest" href="/manifest.json" />
        <meta name="theme-color" content="#eb520a" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
        <meta name="apple-mobile-web-app-title" content="Ceramix" />
      </head>
      <body className="bg-[#050505] text-[#f8f3e7] antialiased">
        <AppLoader>
          {children}
        </AppLoader>
        <script src="/register-sw.js" async></script>
      </body>
    </html>
  );
}


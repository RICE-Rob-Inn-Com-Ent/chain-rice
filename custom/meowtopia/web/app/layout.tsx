import type { Metadata } from "next";
import { Inter, Poppins } from "next/font/google";
import { headers } from "next/headers";
import { Providers } from "@/components/providers";
import Header from "@/components/ui/Header";
import FixedHeart from "@/components/ui/FixedHeart";
import "./globals.css";
import "./animations.css";

const inter = Inter({
  subsets: ["latin", "latin-ext"],
  variable: "--font-inter",
  display: "swap",
  preload: true,
});

const poppins = Poppins({
  subsets: ["latin", "latin-ext"],
  weight: ["300", "400", "500", "600", "700"],
  variable: "--font-poppins",
  display: "swap",
  preload: true,
});

export const metadata: Metadata = {
  title: "MeoWTopia - Kupujesz • Pomagasz | Sklep z misją ratowania zwierząt",
  description: "Przytulny sklep internetowy z kawą, herbatą i ilustracjami kotów. 5% z każdego zamówienia automatycznie wspiera fundacje ratujące zwierzęta. Twoja kawa ratuje zwierzęta!",
  keywords: "kawa, herbata, ilustracje kotów, fundacje zwierząt, sklep z misją, pomoc zwierzętom, sklep online, MeoWTopia",
  authors: [{ name: "MeoWTopia Team" }],
  icons: {
    icon: '/favicon.svg',
    shortcut: '/favicon.svg',
    apple: '/favicon.svg',
  },
  openGraph: {
    title: "MeoWTopia - Kupujesz • Pomagasz",
    description: "5% z każdego zamówienia automatycznie wspiera fundacje ratujące zwierzęta",
    type: "website",
    locale: "pl_PL",
  },
  twitter: {
    card: "summary_large_image",
    title: "MeoWTopia - Kupujesz • Pomagasz",
    description: "5% z każdego zamówienia wspiera fundacje ratujące zwierzęta",
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Check if we're on panel subdomain - if yes, don't show Header
  const headersList = await headers();
  const hostname = headersList.get("host") || "";
  const isPanelSubdomain = hostname.startsWith("panel.") || hostname === "panel.meowtopia.ltd";
  
  return (
    <html lang="pl" className={`${inter.variable} ${poppins.variable}`}>
      <body className="antialiased overflow-x-hidden">
        <Providers>
          {/* Fixed Heart with "KUPUJESZ POMAGASZ" on the left - widoczne na wszystkich stronach */}
          <FixedHeart />
          <div className="min-h-screen flex flex-col relative">
            {/* Header tylko na głównej domenie (meowtopia.ltd), nie na panel subdomain */}
            {!isPanelSubdomain && <Header />}
            <main className="flex-1 relative z-0">
              {children}
            </main>
          </div>
        </Providers>
      </body>
    </html>
  );
}


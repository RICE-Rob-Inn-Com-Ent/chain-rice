// TODO:
// [ ] root layout: ClientProviders, I18nProvider, ThemeProvider, QueryProvider, AudioProvider (Tone) — https://nextjs.org/docs/app/building-your-application/routing/pages-and-layouts
// [ ] metadata: title, OG from NEXT_PUBLIC_APP_NAME; robots noindex when NEXT_PUBLIC_ENV !== production — https://nextjs.org/docs/app/building-your-application/optimizing/metadata
// [ ] fonts: next/font/google → CSS variables — https://nextjs.org/docs/app/building-your-application/optimizing/fonts
// [ ] viewport: themeColor from design tokens — https://nextjs.org/docs/app/api-reference/functions/generate-viewport
// [ ] JSON-LD Organization via schema-dts; name/URL from env — https://schema.org/Organization
//
import "@/browser/styles/globals.css";
import { ClientProviders } from "@/browser/providers/ClientProviders";
import type { Metadata } from "next";
import { Inter } from "next/font/google";

const inter = Inter({
	subsets: ["latin"],
	display: "swap",
	variable: "--font-sans",
});

const defaultTitle = process.env.NEXT_PUBLIC_APP_TITLE ?? "Rice";
const defaultDescription = process.env.NEXT_PUBLIC_APP_DESCRIPTION ?? "";

export const metadata: Metadata = {
	title: defaultTitle,
	description: defaultDescription,
	metadataBase: process.env.NEXT_PUBLIC_APP_URL ? new URL(process.env.NEXT_PUBLIC_APP_URL) : undefined,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
	return (
		<html lang={process.env.NEXT_PUBLIC_DEFAULT_LOCALE ?? "en"} suppressHydrationWarning>
			<body className={`${inter.variable} min-h-dvh font-sans antialiased`}>
				<ClientProviders>{children}</ClientProviders>
			</body>
		</html>
	);
}

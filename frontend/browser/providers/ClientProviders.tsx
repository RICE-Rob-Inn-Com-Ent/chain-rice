"use client";

// TODO:
// [ ] tree: QueryProvider outermost; Theme, I18n, Audio, Rice — https://react.dev/reference/react/Context
// [ ] PostHogProvider when NEXT_PUBLIC_POSTHOG_KEY — https://posthog.com/docs/libraries/next-js
//
import { Toaster } from "sonner";
import type { ReactNode } from "react";
import { AudioProvider } from "@/browser/providers/AudioProvider";
import { I18nProvider } from "@/browser/providers/I18nProvider";
import { QueryProvider } from "@/browser/providers/QueryProvider";
import { RiceProvider } from "@/browser/providers/RiceProvider";
import { ThemeProvider } from "@/browser/providers/ThemeProvider";

export type ClientProvidersProps = {
	children: ReactNode;
};

/**
 * Provider order: Theme → I18n → Query → Rice → Audio (per spec).
 */
export function ClientProviders({ children }: ClientProvidersProps) {
	return (
		<ThemeProvider>
			<I18nProvider>
				<QueryProvider>
					<RiceProvider>
						<AudioProvider>
							{children}
							<Toaster richColors position="top-right" />
						</AudioProvider>
					</RiceProvider>
				</QueryProvider>
			</I18nProvider>
		</ThemeProvider>
	);
}

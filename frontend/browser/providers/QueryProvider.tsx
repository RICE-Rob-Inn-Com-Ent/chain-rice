"use client";

// TODO:
// [ ] QueryClientProvider + Devtools dev-only — https://tanstack.com/query/latest/docs/framework/react/devtools
// [ ] global onError → Sentry + PostHog
//
import { QueryClientProvider } from "@tanstack/react-query";
import type { ReactNode } from "react";
import { queryClient } from "@/browser/lib/query";

export type QueryProviderProps = {
	children: ReactNode;
};

export function QueryProvider({ children }: QueryProviderProps) {
	return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
}

export { queryClient };

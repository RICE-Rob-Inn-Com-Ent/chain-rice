"use client";

// TODO:
// [ ] Server Component: fetch initial data for SEO; Suspense + Skeleton — https://nextjs.org/docs/app/building-your-application/data-fetching
// [ ] JSON-LD WebSite (react-schemaorg) — https://schema.org/WebSite
// [ ] hero: CHIEF .rice manifest when rice cook runs; skeleton until hydrated
//
import { useRice } from "@/browser/providers/RiceProvider";

/**
 * CHIEF injects content via `.rice` hydration — this route stays a composable shell.
 */
export default function HomePage() {
	const { get } = useRice();
	const chiefSlot = get("chief.slot");

	return (
		<main
			data-rice-chief-slot
			className="min-h-dvh"
			suppressHydrationWarning
		>
			{chiefSlot != null ? String(chiefSlot) : null}
		</main>
	);
}

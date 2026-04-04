"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import Link from "next/link";
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type FooterLink = { label: string; href: string };

export type FooterProps = {
	links?: FooterLink[];
	copyright?: ReactNode;
	social?: ReactNode;
	columns?: { title?: string; links: FooterLink[] }[];
	variant?: "minimal" | "full";
	className?: string;
};

export function Footer({ links = [], copyright, social, columns = [], variant = "full", className }: FooterProps) {
	return (
		<footer className={cn("border-t bg-neutral-50 py-10 dark:bg-neutral-950", className)}>
			<div className="mx-auto flex max-w-6xl flex-col gap-8 px-4">
				{variant === "full" && columns.length > 0 ? (
					<div className="grid gap-8 md:grid-cols-3">
						{columns.map((col) => (
							<div key={col.title ?? col.links[0]?.href}>
								{col.title ? <h3 className="mb-3 font-semibold">{col.title}</h3> : null}
								<ul className="space-y-2 text-sm">
									{col.links.map((l) => (
										<li key={l.href}>
											<Link className="hover:underline" href={l.href}>
												{l.label}
											</Link>
										</li>
									))}
								</ul>
							</div>
						))}
					</div>
				) : null}
				<div className="flex flex-wrap items-center justify-between gap-4 text-sm">
					<div className="flex flex-wrap gap-4">
						{links.map((l) => (
							<Link key={l.href} href={l.href} className="hover:underline">
								{l.label}
							</Link>
						))}
					</div>
					<div className="flex items-center gap-3">{social}</div>
				</div>
				{copyright ? <div className="text-xs text-neutral-500">{copyright}</div> : null}
			</div>
		</footer>
	);
}

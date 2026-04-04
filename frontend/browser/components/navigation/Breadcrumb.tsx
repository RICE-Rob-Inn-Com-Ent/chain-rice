"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import Link from "next/link";
import { cn } from "@/browser/lib/cn";

export type BreadcrumbProps = {
	items: { label: string; href?: string }[];
	separator?: React.ReactNode;
	maxItems?: number;
	className?: string;
};

export function Breadcrumb({ items, separator = "/", maxItems = 8, className }: BreadcrumbProps) {
	const visible = items.length > maxItems ? [...items.slice(0, 1), ...items.slice(-(maxItems - 1))] : items;

	return (
		<nav aria-label="Breadcrumb" className={cn("text-sm text-neutral-600 dark:text-neutral-400", className)}>
			<ol className="flex flex-wrap items-center gap-2">
				{visible.map((item, i) => (
					<li key={`${item.label}-${i}`} className="flex items-center gap-2">
						{i > 0 ? <span className="text-neutral-400">{separator}</span> : null}
						{item.href ? (
							<Link className="hover:underline" href={item.href}>
								{item.label}
							</Link>
						) : (
							<span className="font-medium text-neutral-900 dark:text-neutral-100">{item.label}</span>
						)}
					</li>
				))}
			</ol>
		</nav>
	);
}

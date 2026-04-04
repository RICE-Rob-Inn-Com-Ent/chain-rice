"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type ListProps<T> = {
	items: T[];
	renderItem: (item: T, index: number) => ReactNode;
	variant?: "simple" | "divided" | "card";
	loading?: boolean;
	emptyState?: ReactNode;
	className?: string;
};

export function List<T>({ items, renderItem, variant = "simple", loading, emptyState, className }: ListProps<T>) {
	if (loading) {
		return <div className={cn("p-4 text-sm text-neutral-500", className)}>Loading…</div>;
	}
	if (items.length === 0) {
		return <div className={cn("p-4 text-sm text-neutral-500", className)}>{emptyState ?? "No items"}</div>;
	}
	return (
		<ul
			className={cn(
				"flex flex-col",
				variant === "divided" && "divide-y divide-neutral-200 dark:divide-neutral-800",
				variant === "card" && "gap-2",
				className,
			)}
		>
			{items.map((item, index) => (
				<li
					key={index}
					className={cn(variant === "card" && "rounded-lg border border-neutral-200 p-3 dark:border-neutral-800")}
				>
					{renderItem(item, index)}
				</li>
			))}
		</ul>
	);
}

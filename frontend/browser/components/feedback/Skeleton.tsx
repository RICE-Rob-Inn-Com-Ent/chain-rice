"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import type { CSSProperties } from "react";
import { cn } from "@/browser/lib/cn";

export type SkeletonProps = {
	width?: number | string;
	height?: number | string;
	variant?: "text" | "circle" | "rect" | "card";
	animate?: boolean;
	count?: number;
	gap?: number;
	className?: string;
};

export function Skeleton({
	width,
	height = 14,
	variant = "text",
	animate = true,
	count = 1,
	gap = 8,
	className,
}: SkeletonProps) {
	const base = cn(
		"rounded-md bg-neutral-200/80 dark:bg-neutral-800/80",
		animate && "motion-safe:animate-pulse",
		variant === "circle" && "rounded-full",
		className,
	);

	const style: CSSProperties = {
		width: width ?? (variant === "text" ? "100%" : undefined),
		height: variant === "text" ? height : height,
		marginBottom: gap,
	};

	const items = Array.from({ length: count });
	return (
		<>
			{items.map((_, i) => (
				<div
					// biome-ignore lint/suspicious/noArrayIndexKey: static skeleton list
					key={i}
					className={cn(base, variant === "card" && "h-40 w-full")}
					style={style}
				/>
			))}
		</>
	);
}

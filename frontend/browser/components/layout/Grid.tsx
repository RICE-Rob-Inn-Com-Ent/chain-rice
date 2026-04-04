"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import type { CSSProperties, ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type GridProps = {
	cols?: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12;
	gap?: number;
	rowGap?: number;
	className?: string;
	children: ReactNode;
	breakpoints?: Partial<Record<"sm" | "md" | "lg" | "xl", number>>;
};

export function Grid({ cols = 12, gap = 4, rowGap, className, children }: GridProps) {
	const style: CSSProperties = {
		display: "grid",
		gridTemplateColumns: `repeat(${cols}, minmax(0, 1fr))`,
		gap: `${gap * 0.25}rem`,
		rowGap: rowGap != null ? `${rowGap * 0.25}rem` : undefined,
	};

	return (
		<div className={cn("w-full", className)} style={style}>
			{children}
		</div>
	);
}

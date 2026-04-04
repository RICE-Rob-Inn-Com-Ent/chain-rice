"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type CardProps = {
	title?: ReactNode;
	description?: ReactNode;
	media?: ReactNode;
	actions?: ReactNode;
	badge?: ReactNode;
	variant?: "default" | "elevated" | "outlined";
	padding?: "none" | "sm" | "md" | "lg";
	onClick?: () => void;
	loading?: boolean;
	className?: string;
};

const pad: Record<NonNullable<CardProps["padding"]>, string> = {
	none: "p-0",
	sm: "p-3",
	md: "p-4",
	lg: "p-6",
};

export function Card({
	title,
	description,
	media,
	actions,
	badge,
	variant = "default",
	padding = "md",
	onClick,
	loading,
	className,
}: CardProps) {
	return (
		<article
			className={cn(
				"rounded-xl border border-neutral-200 dark:border-neutral-800",
				variant === "elevated" && "shadow-lg",
				variant === "outlined" && "border-2",
				onClick && "cursor-pointer transition hover:border-neutral-400",
				className,
			)}
			onClick={onClick}
			onKeyDown={(e) => e.key === "Enter" && onClick?.()}
			role={onClick ? "button" : undefined}
			tabIndex={onClick ? 0 : undefined}
		>
			{media}
			<div className={cn("relative", pad[padding])}>
				{badge ? <div className="absolute right-3 top-3">{badge}</div> : null}
				{title ? <h3 className="text-lg font-semibold">{title}</h3> : null}
				{description ? <p className="mt-1 text-sm text-neutral-600 dark:text-neutral-400">{description}</p> : null}
				{loading ? <p className="mt-2 text-sm text-neutral-500">Loading…</p> : null}
				{actions ? <div className="mt-4 flex flex-wrap gap-2">{actions}</div> : null}
			</div>
		</article>
	);
}

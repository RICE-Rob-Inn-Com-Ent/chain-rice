"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type TimelineEvent = {
	date?: ReactNode;
	title: ReactNode;
	description?: ReactNode;
	icon?: ReactNode;
	color?: string;
	status?: "done" | "current" | "pending";
};

export type TimelineProps = {
	events: TimelineEvent[];
	orientation?: "horizontal" | "vertical";
	variant?: "default" | "compact";
	className?: string;
};

export function Timeline({ events, orientation = "vertical", variant = "default", className }: TimelineProps) {
	return (
		<ol
			className={cn(
				"flex gap-4",
				orientation === "vertical" ? "flex-col" : "flex-row overflow-x-auto",
				className,
			)}
		>
			{events.map((ev, i) => (
				<li key={i} className={cn("relative flex gap-3", variant === "compact" && "gap-2")}>
					<div
						className="mt-1 h-3 w-3 shrink-0 rounded-full border-2"
						style={{ borderColor: ev.color ?? "currentColor" }}
					/>
					<div>
						{ev.date ? <div className="text-xs text-neutral-500">{ev.date}</div> : null}
						<div className="font-medium">{ev.title}</div>
						{ev.description ? <div className="text-sm text-neutral-600 dark:text-neutral-400">{ev.description}</div> : null}
					</div>
					{ev.icon ? <div className="text-neutral-400">{ev.icon}</div> : null}
				</li>
			))}
		</ol>
	);
}

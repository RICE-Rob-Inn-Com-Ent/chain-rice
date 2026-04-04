"use client";

// TODO:
// [ ] Header + Sidebar + main + Footer; mobile collapse; sidebar width CSS var — https://nextjs.org/docs
//
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type ShellProps = {
	header?: ReactNode;
	sidebar?: ReactNode;
	footer?: ReactNode;
	children: ReactNode;
	className?: string;
};

export function Shell({ header, sidebar, footer, children, className }: ShellProps) {
	return (
		<div className={cn("flex min-h-dvh flex-col", className)}>
			{header}
			<div className="flex flex-1">
				{sidebar}
				<main className="flex-1">{children}</main>
			</div>
			{footer}
		</div>
	);
}

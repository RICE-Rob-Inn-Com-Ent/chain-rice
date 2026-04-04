"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type StatProps = {
	label: ReactNode;
	value: ReactNode;
	delta?: ReactNode;
	deltaType?: "increase" | "decrease";
	icon?: ReactNode;
	trend?: number[];
	loading?: boolean;
	format?: "number" | "currency" | "percent";
	className?: string;
};

function formatValue(v: ReactNode, format: StatProps["format"]) {
	if (typeof v !== "number") return v;
	if (format === "currency") return new Intl.NumberFormat(undefined, { style: "currency", currency: "USD" }).format(v);
	if (format === "percent") return `${v.toFixed(1)}%`;
	return v.toLocaleString();
}

export function Stat({
	label,
	value,
	delta,
	deltaType = "increase",
	icon,
	trend: _trend,
	loading,
	format = "number",
	className,
}: StatProps) {
	return (
		<div className={cn("rounded-lg border border-neutral-200 p-4 dark:border-neutral-800", className)}>
			<div className="flex items-center justify-between gap-2">
				<span className="text-sm text-neutral-500">{label}</span>
				{icon}
			</div>
			<div className="mt-2 text-2xl font-semibold">
				{loading ? "…" : formatValue(value, format)}
			</div>
			{delta != null ? (
				<div
					className={cn(
						"mt-1 text-sm",
						deltaType === "increase" && "text-emerald-600",
						deltaType === "decrease" && "text-rose-600",
					)}
				>
					{delta}
				</div>
			) : null}
		</div>
	);
}

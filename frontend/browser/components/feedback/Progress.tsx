"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { cn } from "@/browser/lib/cn";

export type ProgressProps = {
	value: number;
	max?: number;
	variant?: "bar" | "circle" | "steps";
	size?: "sm" | "md" | "lg";
	color?: string;
	animated?: boolean;
	label?: string;
	showValue?: boolean;
	steps?: number;
	className?: string;
};

export function Progress({
	value,
	max = 100,
	variant = "bar",
	size = "md",
	color,
	animated,
	label,
	showValue,
	steps = 5,
	className,
}: ProgressProps) {
	const pct = Math.min(1, Math.max(0, value / max));
	if (variant === "circle") {
		const r = 18;
		const c = 2 * Math.PI * r;
		return (
			<div className={cn("inline-flex items-center gap-2", className)}>
				<svg width="48" height="48" viewBox="0 0 48 48">
					<circle cx="24" cy="24" r={r} stroke="currentColor" strokeWidth="4" fill="none" className="text-neutral-200" />
					<circle
						cx="24"
						cy="24"
						r={r}
						stroke={color ?? "currentColor"}
						strokeWidth="4"
						fill="none"
						strokeDasharray={c}
						strokeDashoffset={c * (1 - pct)}
						className={cn("origin-center -rotate-90 text-neutral-900 dark:text-neutral-100", animated && "transition-[stroke-dashoffset]")}
					/>
				</svg>
				{showValue ? <span className="text-sm">{Math.round(pct * 100)}%</span> : null}
				{label}
			</div>
		);
	}
	if (variant === "steps") {
		const active = Math.round(pct * steps);
		return (
			<div className={cn("flex gap-1", className)}>
				{Array.from({ length: steps }).map((_, i) => (
					<div
						key={i}
						className={cn(
							"h-2 flex-1 rounded-full",
							i < active ? "bg-neutral-900 dark:bg-neutral-100" : "bg-neutral-200 dark:bg-neutral-800",
						)}
					/>
				))}
			</div>
		);
	}
	const h = size === "sm" ? "h-1" : size === "lg" ? "h-4" : "h-2";
	return (
		<div className={cn("w-full", className)}>
			{label ? <div className="mb-1 text-xs text-neutral-600">{label}</div> : null}
			<div className={cn("w-full overflow-hidden rounded-full bg-neutral-200 dark:bg-neutral-800", h)}>
				<div
					className={cn("h-full rounded-full bg-neutral-900 dark:bg-neutral-100", animated && "transition-[width]")}
					style={{ width: `${pct * 100}%`, backgroundColor: color }}
				/>
			</div>
			{showValue ? <div className="mt-1 text-xs text-neutral-500">{Math.round(pct * 100)}%</div> : null}
		</div>
	);
}

"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type AlertProps = {
	type?: "info" | "success" | "warning" | "error";
	title?: ReactNode;
	message?: ReactNode;
	dismissible?: boolean;
	onDismiss?: () => void;
	icon?: ReactNode;
	actions?: ReactNode;
	variant?: "solid" | "subtle" | "outline";
	className?: string;
};

const tone: Record<NonNullable<AlertProps["type"]>, string> = {
	info: "border-blue-200 bg-blue-50 text-blue-900 dark:border-blue-900 dark:bg-blue-950 dark:text-blue-100",
	success: "border-emerald-200 bg-emerald-50 text-emerald-900 dark:border-emerald-900 dark:bg-emerald-950 dark:text-emerald-100",
	warning: "border-amber-200 bg-amber-50 text-amber-900 dark:border-amber-900 dark:bg-amber-950 dark:text-amber-100",
	error: "border-rose-200 bg-rose-50 text-rose-900 dark:border-rose-900 dark:bg-rose-950 dark:text-rose-100",
};

export function Alert({
	type = "info",
	title,
	message,
	dismissible,
	onDismiss,
	icon,
	actions,
	variant = "subtle",
	className,
}: AlertProps) {
	return (
		<div
			className={cn(
				"flex gap-3 rounded-lg border p-4",
				tone[type],
				variant === "outline" && "bg-transparent",
				variant === "solid" && "text-white",
				className,
			)}
			role="status"
		>
			{icon}
			<div className="flex-1">
				{title ? <div className="font-semibold">{title}</div> : null}
				{message ? <div className="text-sm opacity-90">{message}</div> : null}
				{actions ? <div className="mt-2 flex gap-2">{actions}</div> : null}
			</div>
			{dismissible ? (
				<button type="button" className="text-sm" onClick={onDismiss} aria-label="Dismiss">
					×
				</button>
			) : null}
		</div>
	);
}

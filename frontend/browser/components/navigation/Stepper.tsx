"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type StepperStep = {
	label: string;
	description?: string;
	icon?: ReactNode;
	status?: "complete" | "current" | "upcoming";
};

export type StepperProps = {
	steps: StepperStep[];
	current: number;
	orientation?: "horizontal" | "vertical";
	variant?: "default" | "circles" | "numbers";
	className?: string;
};

export function Stepper({ steps, current, orientation = "horizontal", variant = "default", className }: StepperProps) {
	return (
		<ol
			className={cn(
				"flex gap-4",
				orientation === "vertical" ? "flex-col" : "flex-row flex-wrap",
				className,
			)}
		>
			{steps.map((step, index) => {
				const state = step.status ?? (index < current ? "complete" : index === current ? "current" : "upcoming");
				return (
					<li key={step.label} className="flex items-start gap-3">
						<div
							className={cn(
								"flex h-8 w-8 shrink-0 items-center justify-center rounded-full border text-xs font-medium",
								state === "complete" && "border-emerald-600 bg-emerald-600 text-white",
								state === "current" && "border-neutral-900 dark:border-neutral-100",
								variant === "circles" && "rounded-full",
							)}
						>
							{variant === "numbers" ? index + 1 : step.icon}
						</div>
						<div>
							<div className="font-medium">{step.label}</div>
							{step.description ? <div className="text-sm text-neutral-500">{step.description}</div> : null}
						</div>
					</li>
				);
			})}
		</ol>
	);
}

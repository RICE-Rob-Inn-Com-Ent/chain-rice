"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { cn } from "@/browser/lib/cn";

export type ToggleProps = {
	checked: boolean;
	onChange: (v: boolean) => void;
	label?: string;
	labelPosition?: "left" | "right";
	size?: "sm" | "md" | "lg";
	disabled?: boolean;
	variant?: "switch" | "checkbox";
	className?: string;
};

export function Toggle({
	checked,
	onChange,
	label,
	labelPosition = "right",
	size = "md",
	disabled,
	variant = "switch",
	className,
}: ToggleProps) {
	const control =
		variant === "switch" ? (
			<button
				type="button"
				role="switch"
				aria-checked={checked}
				disabled={disabled}
				className={cn(
					"inline-flex h-7 w-12 items-center rounded-full border transition-colors",
					checked ? "bg-neutral-900 dark:bg-neutral-100" : "bg-neutral-200 dark:bg-neutral-800",
				)}
				onClick={() => onChange(!checked)}
			>
				<span
					className={cn(
						"ml-1 inline-block h-5 w-5 rounded-full bg-white transition-transform",
						checked && "translate-x-5",
					)}
				/>
			</button>
		) : (
			<input
				type="checkbox"
				checked={checked}
				disabled={disabled}
				onChange={(e) => onChange(e.target.checked)}
			/>
		);

	return (
		<label
			className={cn(
				"inline-flex items-center gap-2",
				labelPosition === "left" && "flex-row-reverse",
				size === "sm" && "text-sm",
				size === "lg" && "text-lg",
				className,
			)}
		>
			{control}
			{label}
		</label>
	);
}

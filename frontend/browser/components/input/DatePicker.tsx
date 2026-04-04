"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { DayPicker } from "react-day-picker";
import { cn } from "@/browser/lib/cn";
import "react-day-picker/style.css";

export type DatePickerProps = {
	value?: Date | { from?: Date; to?: Date };
	onChange: (v: Date | { from?: Date; to?: Date } | undefined) => void;
	mode?: "single" | "range";
	locale?: string;
	minDate?: Date;
	maxDate?: Date;
	format?: string;
	placeholder?: string;
	disabled?: boolean;
	className?: string;
};

export function DatePicker({
	value,
	onChange,
	mode = "single",
	minDate,
	maxDate,
	disabled,
	className,
}: DatePickerProps) {
	if (mode === "range") {
		const range =
			value && typeof value === "object" && "from" in value
				? { from: (value as { from?: Date }).from, to: (value as { to?: Date }).to }
				: undefined;
		return (
			<div className={cn("rounded-md border p-2", className)}>
				<DayPicker
					mode="range"
					selected={range}
					onSelect={(r) => onChange(r ?? undefined)}
					disabled={disabled}
					fromDate={minDate}
					toDate={maxDate}
				/>
			</div>
		);
	}
	const selected = value instanceof Date ? value : undefined;
	return (
		<div className={cn("rounded-md border p-2", className)}>
			<DayPicker
				mode="single"
				selected={selected}
				onSelect={(d) => onChange(d)}
				disabled={disabled}
				fromDate={minDate}
				toDate={maxDate}
			/>
		</div>
	);
}

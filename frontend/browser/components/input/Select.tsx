"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { useMemo, useState } from "react";
import { cn } from "@/browser/lib/cn";

export type SelectOption = { label: string; value: string; group?: string };

export type SelectProps = {
	options: SelectOption[];
	value?: string | string[];
	onChange: (v: string | string[]) => void;
	multiple?: boolean;
	searchable?: boolean;
	placeholder?: string;
	disabled?: boolean;
	loading?: boolean;
	clearable?: boolean;
	className?: string;
};

export function Select({
	options,
	value,
	onChange,
	multiple,
	searchable,
	placeholder = "Select…",
	disabled,
	loading,
	clearable,
	className,
}: SelectProps) {
	const [q, setQ] = useState("");
	const filtered = useMemo(() => {
		if (!searchable || !q) return options;
		return options.filter((o) => o.label.toLowerCase().includes(q.toLowerCase()));
	}, [options, q, searchable]);

	return (
		<div className={cn("relative w-full", className)}>
			{searchable ? (
				<input
					className="mb-2 w-full rounded-md border px-2 py-1 text-sm"
					value={q}
					onChange={(e) => setQ(e.target.value)}
					placeholder="Search"
				/>
			) : null}
			<select
				className="w-full rounded-md border border-neutral-300 bg-white px-3 py-2 text-sm dark:border-neutral-700 dark:bg-neutral-950"
				disabled={disabled || loading}
				multiple={multiple}
				value={multiple ? (value as string[] | undefined) : (value as string | undefined)}
				onChange={(e) => {
					if (multiple) {
						const vals = Array.from(e.target.selectedOptions).map((o) => o.value);
						onChange(vals);
					} else {
						onChange(e.target.value);
					}
				}}
			>
				<option value="">{placeholder}</option>
				{filtered.map((o) => (
					<option key={o.value} value={o.value} label={o.group ? `${o.group} / ${o.label}` : o.label}>
						{o.label}
					</option>
				))}
			</select>
			{clearable ? (
				<button
					type="button"
					className="mt-1 text-xs text-neutral-500"
					onClick={() => onChange(multiple ? [] : "")}
				>
					Clear
				</button>
			) : null}
		</div>
	);
}

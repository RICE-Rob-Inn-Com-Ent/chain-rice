"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { useEffect, useState, type ReactNode } from "react";
import { cn } from "@/browser/lib/cn";
import type { SelectOption } from "@/browser/components/input/Select";

export type ComboboxProps = {
	onSearch: (query: string) => void | Promise<void>;
	options: SelectOption[];
	value?: string;
	onChange: (v: string) => void;
	async?: boolean;
	debounceMs?: number;
	renderOption?: (opt: SelectOption) => ReactNode;
	className?: string;
};

export function Combobox({
	onSearch,
	options,
	value,
	onChange,
	async: _async,
	debounceMs = 200,
	renderOption,
	className,
}: ComboboxProps) {
	const [q, setQ] = useState("");
	useEffect(() => {
		const t = setTimeout(() => {
			void onSearch(q);
		}, debounceMs);
		return () => clearTimeout(t);
	}, [q, onSearch, debounceMs]);

	return (
		<div className={cn("relative w-full", className)}>
			<input
				className="w-full rounded-md border px-3 py-2 text-sm"
				value={q}
				onChange={(e) => setQ(e.target.value)}
				placeholder="Type to search"
			/>
			<ul className="absolute z-20 mt-1 max-h-48 w-full overflow-auto rounded-md border bg-white shadow dark:bg-neutral-950">
				{options.map((o) => (
					<li key={o.value}>
						<button
							type="button"
							className="w-full px-3 py-2 text-left text-sm hover:bg-neutral-100 dark:hover:bg-neutral-900"
							onClick={() => onChange(o.value)}
						>
							{renderOption ? renderOption(o) : o.label}
						</button>
					</li>
				))}
			</ul>
			{value ? <div className="mt-1 text-xs text-neutral-500">Selected: {value}</div> : null}
		</div>
	);
}

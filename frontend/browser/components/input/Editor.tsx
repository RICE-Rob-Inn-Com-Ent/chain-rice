"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type EditorProps = {
	value: string;
	onChange: (v: string) => void;
	mode?: "markdown" | "rich";
	placeholder?: string;
	toolbar?: ReactNode;
	height?: number | string;
	readonly?: boolean;
	className?: string;
};

export function Editor({
	value,
	onChange,
	mode = "markdown",
	placeholder,
	toolbar,
	height = 240,
	readonly,
	className,
}: EditorProps) {
	return (
		<div className={cn("flex flex-col gap-2 rounded-md border", className)}>
			{toolbar ? <div className="border-b px-2 py-1">{toolbar}</div> : null}
			<textarea
				className="w-full resize-y bg-transparent px-3 py-2 text-sm outline-none"
				style={{ minHeight: height }}
				value={value}
				readOnly={readonly}
				placeholder={placeholder}
				spellCheck={mode === "markdown"}
				onChange={(e) => onChange(e.target.value)}
			/>
		</div>
	);
}

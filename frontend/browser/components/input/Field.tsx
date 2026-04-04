"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

/** TanStack Form instance from `useForm()` — includes `.Field` render prop. */
// biome-ignore lint/suspicious/noExplicitAny: generic service form surface
export type RiceFormApi = any;

export type FieldProps = {
	form: RiceFormApi;
	name: string;
	label?: ReactNode;
	type?: string;
	placeholder?: string;
	hint?: ReactNode;
	error?: ReactNode;
	required?: boolean;
	disabled?: boolean;
	prefix?: ReactNode;
	suffix?: ReactNode;
	size?: "sm" | "md" | "lg";
	className?: string;
};

const sizeCls: Record<NonNullable<FieldProps["size"]>, string> = {
	sm: "h-8 text-sm",
	md: "h-10 text-sm",
	lg: "h-12 text-base",
};

export function Field({
	form: formApi,
	name,
	label,
	type = "text",
	placeholder,
	hint,
	error,
	required,
	disabled,
	prefix,
	suffix,
	size = "md",
	className,
}: FieldProps) {
	return (
		<formApi.Field name={name}>
			{(field: {
				state: { value: unknown; meta: { errors?: unknown[] } };
				handleChange: (v: string) => void;
				handleBlur: () => void;
			}) => (
				<label className={cn("flex flex-col gap-1 text-sm", className)}>
					{label ? (
						<span>
							{label}
							{required ? <span className="text-rose-500"> *</span> : null}
						</span>
					) : null}
					<div className="flex items-stretch overflow-hidden rounded-md border border-neutral-300 dark:border-neutral-700">
						{prefix ? <span className="flex items-center border-r px-2 text-neutral-500">{prefix}</span> : null}
						<input
							className={cn(
								"w-full min-w-0 bg-transparent px-3 outline-none ring-0",
								sizeCls[size],
								disabled && "cursor-not-allowed opacity-60",
							)}
							type={type}
							placeholder={placeholder}
							disabled={disabled}
							value={String(field.state.value ?? "")}
							onChange={(e) => field.handleChange(e.target.value)}
							onBlur={field.handleBlur}
						/>
						{suffix ? <span className="flex items-center border-l px-2 text-neutral-500">{suffix}</span> : null}
					</div>
					{field.state.meta.errors?.length ? (
						<span className="text-xs text-rose-600">{String(field.state.meta.errors[0])}</span>
					) : null}
					{error ? <span className="text-xs text-rose-600">{error}</span> : null}
					{hint ? <span className="text-xs text-neutral-500">{hint}</span> : null}
				</label>
			)}
		</formApi.Field>
	);
}

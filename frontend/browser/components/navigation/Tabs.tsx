"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import * as TabsPrimitive from "@radix-ui/react-tabs";
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type TabItem = {
	label: string;
	value: string;
	content?: ReactNode;
	icon?: ReactNode;
	disabled?: boolean;
};

export type TabsProps = {
	items: TabItem[];
	defaultValue?: string;
	orientation?: "horizontal" | "vertical";
	variant?: "line" | "enclosed" | "soft";
	className?: string;
};

export function Tabs({ items, defaultValue, orientation = "horizontal", variant = "line", className }: TabsProps) {
	const first = items[0]?.value ?? "";
	return (
		<TabsPrimitive.Root
			className={cn("w-full", className)}
			defaultValue={defaultValue ?? first}
			orientation={orientation}
		>
			<TabsPrimitive.List
				className={cn(
					"flex gap-1",
					orientation === "vertical" && "flex-col",
					variant === "enclosed" && "rounded-md border p-1",
					variant === "soft" && "rounded-md bg-neutral-100 p-1 dark:bg-neutral-900",
				)}
			>
				{items.map((item) => (
					<TabsPrimitive.Trigger
						key={item.value}
						value={item.value}
						disabled={item.disabled}
						className={cn(
							"flex items-center gap-2 rounded-md px-3 py-2 text-sm data-[state=active]:bg-white data-[state=active]:shadow-sm dark:data-[state=active]:bg-neutral-950",
							variant === "line" &&
								"border-b-2 border-transparent data-[state=active]:border-neutral-900 dark:data-[state=active]:border-neutral-100",
						)}
					>
						{item.icon}
						{item.label}
					</TabsPrimitive.Trigger>
				))}
			</TabsPrimitive.List>
			{items.map((item) => (
				<TabsPrimitive.Content key={item.value} value={item.value} className="mt-4 outline-none">
					{item.content}
				</TabsPrimitive.Content>
			))}
		</TabsPrimitive.Root>
	);
}

"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import * as TooltipPrimitive from "@radix-ui/react-tooltip";
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type TooltipProps = {
	content: ReactNode;
	children: ReactNode;
	side?: "top" | "right" | "bottom" | "left";
	align?: "start" | "center" | "end";
	delay?: number;
	multiline?: boolean;
	className?: string;
};

export function Tooltip({ content, children, side = "top", align = "center", delay = 200, multiline, className }: TooltipProps) {
	return (
		<TooltipPrimitive.Provider delayDuration={delay}>
			<TooltipPrimitive.Root>
				<TooltipPrimitive.Trigger asChild>{children}</TooltipPrimitive.Trigger>
				<TooltipPrimitive.Portal>
					<TooltipPrimitive.Content
						side={side}
						align={align}
						className={cn(
							"z-50 rounded-md border bg-neutral-950 px-2 py-1 text-xs text-white shadow",
							multiline && "max-w-xs whitespace-pre-wrap",
							className,
						)}
					>
						{content}
					</TooltipPrimitive.Content>
				</TooltipPrimitive.Portal>
			</TooltipPrimitive.Root>
		</TooltipPrimitive.Provider>
	);
}

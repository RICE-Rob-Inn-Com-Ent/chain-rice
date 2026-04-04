"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type DrawerProps = {
	open: boolean;
	onClose: () => void;
	title?: ReactNode;
	children?: ReactNode;
	side?: "left" | "right" | "top" | "bottom";
	size?: number | string;
	overlay?: boolean;
	closeButton?: boolean;
	className?: string;
};

export function Drawer({
	open,
	onClose,
	title,
	children,
	side = "right",
	size = 320,
	overlay = true,
	closeButton = true,
	className,
}: DrawerProps) {
	if (!open) return null;
	return (
		<div className="fixed inset-0 z-50">
			{overlay ? (
				<button type="button" className="absolute inset-0 bg-black/40" aria-label="Close" onClick={onClose} />
			) : null}
			<div
				className={cn(
					"absolute z-10 flex h-full flex-col bg-white shadow-xl dark:bg-neutral-950",
					side === "right" && "right-0 top-0",
					side === "left" && "left-0 top-0",
					side === "top" && "left-0 top-0 w-full",
					side === "bottom" && "bottom-0 left-0 w-full",
					className,
				)}
				style={
					side === "left" || side === "right"
						? { width: size }
						: { height: size }
				}
			>
				<div className="flex items-center justify-between border-b px-4 py-3">
					<div className="font-semibold">{title}</div>
					{closeButton ? (
						<button type="button" onClick={onClose} aria-label="Close">
							×
						</button>
					) : null}
				</div>
				<div className="flex-1 overflow-auto p-4">{children}</div>
			</div>
		</div>
	);
}

"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import * as Dialog from "@radix-ui/react-dialog";
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type ModalProps = {
	open: boolean;
	onClose: () => void;
	title?: ReactNode;
	description?: ReactNode;
	children?: ReactNode;
	actions?: ReactNode;
	size?: "sm" | "md" | "lg" | "xl" | "full";
	closeOnOverlay?: boolean;
	closeOnEsc?: boolean;
	className?: string;
};

const sizes: Record<NonNullable<ModalProps["size"]>, string> = {
	sm: "max-w-sm",
	md: "max-w-md",
	lg: "max-w-lg",
	xl: "max-w-xl",
	full: "max-w-[100vw]",
};

export function Modal({
	open,
	onClose,
	title,
	description,
	children,
	actions,
	size = "md",
	closeOnOverlay = true,
	closeOnEsc = true,
	className,
}: ModalProps) {
	return (
		<Dialog.Root open={open} onOpenChange={(o) => !o && onClose()}>
			<Dialog.Portal>
				<Dialog.Overlay className="fixed inset-0 z-50 bg-black/40 data-[state=open]:animate-in" />
				<Dialog.Content
					className={cn(
						"fixed left-1/2 top-1/2 z-50 w-[90vw] -translate-x-1/2 -translate-y-1/2 rounded-xl border bg-white p-6 shadow-xl dark:bg-neutral-950",
						sizes[size],
						className,
					)}
					onPointerDownOutside={() => closeOnOverlay && onClose()}
					onEscapeKeyDown={() => closeOnEsc && onClose()}
				>
					{title ? <Dialog.Title className="text-lg font-semibold">{title}</Dialog.Title> : null}
					{description ? (
						<Dialog.Description className="mt-1 text-sm text-neutral-600 dark:text-neutral-400">
							{description}
						</Dialog.Description>
					) : null}
					<div className="mt-4">{children}</div>
					{actions ? <div className="mt-6 flex justify-end gap-2">{actions}</div> : null}
				</Dialog.Content>
			</Dialog.Portal>
		</Dialog.Root>
	);
}

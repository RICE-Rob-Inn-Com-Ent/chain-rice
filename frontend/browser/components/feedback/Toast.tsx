"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { toast as sonnerToast } from "sonner";

export type ToastProps = {
	message: string;
	type?: "info" | "success" | "warning" | "error";
	duration?: number;
	position?: "top-left" | "top-right" | "bottom-left" | "bottom-right";
	onClose?: () => void;
};

export const toast = {
	success: (msg: string, opts?: Partial<ToastProps>) => sonnerToast.success(msg, { duration: opts?.duration }),
	error: (msg: string, opts?: Partial<ToastProps>) => sonnerToast.error(msg, { duration: opts?.duration }),
	info: (msg: string, opts?: Partial<ToastProps>) => sonnerToast.message(msg, { duration: opts?.duration }),
	warning: (msg: string, opts?: Partial<ToastProps>) => sonnerToast.warning(msg, { duration: opts?.duration }),
};

export function Toast(_props: ToastProps) {
	return null;
}

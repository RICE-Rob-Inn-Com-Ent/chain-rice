"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import * as Lucide from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { cn } from "@/browser/lib/cn";

export type IconProps = {
	name: string;
	size?: number;
	color?: string;
	strokeWidth?: number;
	library?: "lucide" | "custom";
	className?: string;
	onClick?: () => void;
};

export function Icon({ name, size = 24, color, strokeWidth = 2, library = "lucide", className, onClick }: IconProps) {
	if (library === "custom") {
		return <span className={cn("inline-block", className)} style={{ width: size, height: size, color }} />;
	}
	const Cmp = (Lucide as unknown as Record<string, LucideIcon | undefined>)[name];
	if (!Cmp) return null;
	return (
		<Cmp size={size} color={color} strokeWidth={strokeWidth} className={cn(className)} onClick={onClick} aria-hidden />
	);
}

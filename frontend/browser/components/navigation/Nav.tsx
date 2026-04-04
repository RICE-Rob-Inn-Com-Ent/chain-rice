"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import Link from "next/link";
import { cn } from "@/browser/lib/cn";

export type NavItem = { label: string; href: string; active?: boolean };

export type NavProps = {
	items: NavItem[];
	orientation?: "horizontal" | "vertical";
	variant?: "default" | "pills" | "underline";
	activeHref?: string;
	onNavigate?: (href: string) => void;
	className?: string;
};

export function Nav({
	items,
	orientation = "horizontal",
	variant = "default",
	activeHref,
	onNavigate,
	className,
}: NavProps) {
	return (
		<nav
			className={cn(
				"flex gap-2",
				orientation === "vertical" ? "flex-col" : "flex-row flex-wrap",
				className,
			)}
		>
			{items.map((item) => {
				const active = activeHref ? item.href === activeHref : item.active;
				return (
					<Link
						key={item.href}
						href={item.href}
						className={cn(
							"rounded-md px-3 py-1.5 text-sm transition-colors",
							variant === "pills" && active && "bg-neutral-900 text-white dark:bg-neutral-100 dark:text-neutral-900",
							variant === "underline" &&
								active &&
								"border-b-2 border-neutral-900 dark:border-neutral-100",
							variant === "default" && "hover:bg-neutral-100 dark:hover:bg-neutral-900",
						)}
						onClick={() => onNavigate?.(item.href)}
					>
						{item.label}
					</Link>
				);
			})}
		</nav>
	);
}

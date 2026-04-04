"use client";

// TODO:
// [ ] logo, nav, user menu, theme toggle; cook + model badges from stores
//
import { motion, useScroll, useTransform } from "motion/react";
import type { ReactNode } from "react";
import { useEffect, useState } from "react";
import { cn } from "@/browser/lib/cn";
import { Nav } from "@/browser/components/navigation/Nav";

export type HeaderProps = {
	logo?: string | ReactNode;
	title?: string;
	nav?: { label: string; href: string; active?: boolean }[];
	actions?: ReactNode;
	theme?: "light" | "dark" | "transparent";
	sticky?: boolean;
	height?: number;
	className?: string;
};

export function Header({
	logo,
	title,
	nav = [],
	actions,
	theme = "light",
	sticky = true,
	height = 64,
	className,
}: HeaderProps) {
	const { scrollY } = useScroll();
	const y = useTransform(scrollY, [0, 120], [0, -12]);
	const [open, setOpen] = useState(false);
	const [hidden, setHidden] = useState(false);
	const [lastY, setLastY] = useState(0);

	useEffect(() => {
		const onScroll = () => {
			const yv = window.scrollY;
			setHidden(yv > lastY && yv > 80);
			setLastY(yv);
		};
		window.addEventListener("scroll", onScroll, { passive: true });
		return () => window.removeEventListener("scroll", onScroll);
	}, [lastY]);

	return (
		<motion.header
			style={{ y: hidden ? -height : 0 }}
			className={cn(
				"left-0 right-0 z-40 w-full border-b backdrop-blur",
				sticky && "sticky top-0",
				theme === "transparent" && "border-transparent bg-transparent",
				theme === "dark" && "border-neutral-800 bg-neutral-950/80",
				theme === "light" && "border-neutral-200 bg-white/80",
				className,
			)}
			initial={{ opacity: 0, y: -8 }}
			animate={{ opacity: 1, y: 0 }}
			transition={{ duration: 0.25 }}
		>
			<div
				className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4"
				style={{ minHeight: height }}
			>
				<div className="flex items-center gap-3">
					{logo != null ? <span className="inline-flex shrink-0">{logo}</span> : null}
					{title ? <span className="font-semibold">{title}</span> : null}
					<div className="hidden md:block">
						<Nav items={nav} orientation="horizontal" variant="underline" />
					</div>
				</div>
				<div className="flex items-center gap-2">{actions}</div>
				<button
					type="button"
					className="md:hidden"
					onClick={() => setOpen((v) => !v)}
					aria-label="Menu"
				>
					☰
				</button>
			</div>
			{open ? (
				<motion.div style={{ y }} className="border-t px-4 py-3 md:hidden">
					<Nav items={nav} orientation="vertical" variant="default" />
				</motion.div>
			) : null}
		</motion.header>
	);
}

"use client";

// TODO:
// [ ] collapsible via ui store; nav from router; project selector from rice store
//
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type SidebarItem = { label: string; href: string; icon?: ReactNode };

export type SidebarProps = {
	items: SidebarItem[];
	collapsed?: boolean;
	onCollapse?: (collapsed: boolean) => void;
	width?: number;
	position?: "left" | "right";
	overlay?: boolean;
	className?: string;
};

export function Sidebar({
	items,
	collapsed = false,
	onCollapse,
	width = 260,
	position = "left",
	overlay = false,
	className,
}: SidebarProps) {
	return (
		<>
			{overlay ? <div className="fixed inset-0 z-30 bg-black/30 md:hidden" aria-hidden /> : null}
			<aside
				className={cn(
					"fixed top-0 z-40 h-full border-neutral-200 bg-white shadow-lg transition-[width] dark:border-neutral-800 dark:bg-neutral-950",
					position === "left" ? "left-0 border-r" : "right-0 border-l",
					className,
				)}
				style={{ width: collapsed ? 72 : width }}
			>
				<div className="flex h-14 items-center justify-between px-3">
					<button
						type="button"
						className="text-sm"
						onClick={() => onCollapse?.(!collapsed)}
						aria-label="Toggle sidebar"
					>
						{collapsed ? "»" : "«"}
					</button>
				</div>
				<nav className="flex flex-col gap-1 px-2">
					{items.map((item) => (
						<a
							key={item.href}
							href={item.href}
							className="flex items-center gap-2 rounded-md px-2 py-2 text-sm hover:bg-neutral-100 dark:hover:bg-neutral-900"
						>
							{item.icon}
							<span className={cn(collapsed && "hidden")}>{item.label}</span>
						</a>
					))}
				</nav>
			</aside>
		</>
	);
}

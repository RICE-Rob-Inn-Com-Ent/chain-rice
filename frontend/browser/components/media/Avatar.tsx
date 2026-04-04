"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { cn } from "@/browser/lib/cn";
import { Image } from "@/browser/components/media/Image";

export type AvatarProps = {
	src?: string;
	name?: string;
	size?: "xs" | "sm" | "md" | "lg" | "xl";
	status?: "online" | "offline" | "away";
	fallback?: string;
	group?: boolean;
	count?: number;
	className?: string;
};

const sizes: Record<NonNullable<AvatarProps["size"]>, number> = {
	xs: 24,
	sm: 32,
	md: 40,
	lg: 48,
	xl: 64,
};

export function Avatar({ src, name, size = "md", status, fallback, group, count, className }: AvatarProps) {
	const dim = sizes[size];
	const initials = (name ?? fallback ?? "?")
		.split(" ")
		.map((s) => s[0])
		.join("")
		.slice(0, 2)
		.toUpperCase();

	return (
		<div
			className={cn(
				"relative inline-flex items-center justify-center rounded-full bg-neutral-200 font-medium dark:bg-neutral-800",
				group && "-ml-2 first:ml-0 ring-2 ring-white dark:ring-neutral-950",
				className,
			)}
			style={{ width: dim, height: dim, fontSize: dim / 3 }}
		>
			{src ? (
				<Image src={src} alt={name ?? ""} width={dim} height={dim} className="rounded-full" rounded />
			) : (
				initials
			)}
			{status ? (
				<span
					className={cn(
						"absolute bottom-0 right-0 h-2.5 w-2.5 rounded-full ring-2 ring-white dark:ring-neutral-950",
						status === "online" && "bg-emerald-500",
						status === "offline" && "bg-neutral-400",
						status === "away" && "bg-amber-500",
					)}
				/>
			) : null}
			{count != null ? <span className="absolute -right-1 -top-1 rounded-full bg-neutral-900 px-1 text-[10px] text-white">{count}</span> : null}
		</div>
	);
}

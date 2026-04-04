"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import NextImage from "next/image";
import { useState } from "react";
import { cn } from "@/browser/lib/cn";
import { Skeleton } from "@/browser/components/feedback/Skeleton";

export type RiceImageProps = {
	src: string;
	alt: string;
	width?: number;
	height?: number;
	fit?: "cover" | "contain" | "fill";
	lazy?: boolean;
	placeholder?: "blur" | "skeleton" | "color";
	priority?: boolean;
	rounded?: boolean | string;
	onClick?: () => void;
	className?: string;
};

export function Image({
	src,
	alt,
	width = 800,
	height = 600,
	fit = "cover",
	lazy,
	placeholder = "skeleton",
	priority,
	rounded,
	onClick,
	className,
}: RiceImageProps) {
	const [loaded, setLoaded] = useState(false);
	return (
		<div
			className={cn("relative overflow-hidden", typeof rounded === "string" ? rounded : rounded && "rounded-lg", className)}
			onClick={onClick}
			role={onClick ? "button" : undefined}
		>
			{!loaded && placeholder === "skeleton" ? (
				<Skeleton className="absolute inset-0 h-full w-full" variant="rect" height="100%" />
			) : null}
			<NextImage
				src={src}
				alt={alt}
				width={width}
				height={height}
				priority={priority}
				loading={lazy ? "lazy" : "eager"}
				className={cn("h-full w-full transition-opacity", fit === "cover" && "object-cover", fit === "contain" && "object-contain", !loaded && "opacity-0")}
				onLoadingComplete={() => setLoaded(true)}
			/>
		</div>
	);
}

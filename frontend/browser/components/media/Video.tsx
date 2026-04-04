"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import type { ReactNode } from "react";
import { cn } from "@/browser/lib/cn";

export type VideoProps = {
	src: string;
	poster?: string;
	controls?: boolean;
	autoplay?: boolean;
	loop?: boolean;
	muted?: boolean;
	width?: number | string;
	height?: number | string;
	onPlay?: () => void;
	onPause?: () => void;
	onEnded?: () => void;
	captions?: ReactNode;
	className?: string;
};

export function Video({
	src,
	poster,
	controls = true,
	autoplay,
	loop,
	muted,
	width = "100%",
	height = "auto",
	onPlay,
	onPause,
	onEnded,
	captions,
	className,
}: VideoProps) {
	return (
		<div className={cn("relative w-full", className)} style={{ width, height }}>
			<video
				className="w-full rounded-lg"
				src={src}
				poster={poster}
				controls={controls}
				autoPlay={autoplay}
				loop={loop}
				muted={muted}
				onPlay={onPlay}
				onPause={onPause}
				onEnded={onEnded}
			/>
			{captions}
		</div>
	);
}

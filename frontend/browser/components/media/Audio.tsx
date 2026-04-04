"use client";

// TODO:
// [ ] Composable BARD primitive — props/slots only; CHIEF fills .rice (https://nextjs.org/docs)
// [ ] Soft-code: copy, URLs, test hooks via NEXT_PUBLIC_* and lib/env — never tenant literals
// [ ] Docs: TanStack https://tanstack.com/query/latest/docs · Zustand https://docs.pmnd.rs/zustand · Motion https://www.framer.com/motion/
//
import { cn } from "@/browser/lib/cn";

export type AudioProps = {
	src: string;
	tone?: "synth" | "player" | "sampler";
	visualizer?: boolean;
	controls?: boolean;
	autoplay?: boolean;
	loop?: boolean;
	onPlay?: () => void;
	onPause?: () => void;
	className?: string;
};

/** HTML5 audio by default; Tone.js instruments should be composed via `useSynth` / `usePlayer` at call sites. */
export function Audio({
	src,
	tone: _tone,
	visualizer,
	controls = true,
	autoplay,
	loop,
	onPlay,
	onPause,
	className,
}: AudioProps) {
	return (
		<div className={cn("flex min-w-[240px] items-center gap-2 rounded-md border p-2", className)}>
			<audio src={src} controls={controls} autoPlay={autoplay} loop={loop} onPlay={onPlay} onPause={onPause} />
			{visualizer ? <div className="h-8 flex-1 rounded bg-neutral-100 dark:bg-neutral-900" /> : null}
		</div>
	);
}

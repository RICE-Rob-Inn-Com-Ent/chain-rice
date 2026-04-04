"use client";

// TODO:
// [ ] useBreakpoint, useIsMobile, useIsTablet — matchMedia — https://developer.mozilla.org/en-US/docs/Web/API/Window/matchMedia
// [ ] useCameraDevices / useAudioDevices + hardware WebSocket from env
//
import { useEffect, useState } from "react";

export type Breakpoint = "xs" | "sm" | "md" | "lg" | "xl";

const queries: Record<Breakpoint, string> = {
	xs: "(max-width: 639px)",
	sm: "(min-width: 640px) and (max-width: 767px)",
	md: "(min-width: 768px) and (max-width: 1023px)",
	lg: "(min-width: 1024px) and (max-width: 1279px)",
	xl: "(min-width: 1280px)",
};

export function useBreakpoint(): Breakpoint {
	const [bp, setBp] = useState<Breakpoint>("md");

	useEffect(() => {
		const handlers: Array<() => void> = [];
		const update = () => {
			const order: Breakpoint[] = ["xl", "lg", "md", "sm", "xs"];
			for (const key of order) {
				if (window.matchMedia(queries[key]).matches) {
					setBp(key);
					return;
				}
			}
			setBp("xs");
		};
		update();
		for (const key of Object.keys(queries) as Breakpoint[]) {
			const mq = window.matchMedia(queries[key]);
			const fn = () => update();
			mq.addEventListener("change", fn);
			handlers.push(() => mq.removeEventListener("change", fn));
		}
		return () => handlers.forEach((h) => h());
	}, []);

	return bp;
}

export function useOrientation(): "portrait" | "landscape" {
	const [o, setO] = useState<"portrait" | "landscape">("portrait");
	useEffect(() => {
		const mq = window.matchMedia("(orientation: portrait)");
		const fn = () => setO(mq.matches ? "portrait" : "landscape");
		fn();
		mq.addEventListener("change", fn);
		return () => mq.removeEventListener("change", fn);
	}, []);
	return o;
}

export function useReducedMotion(): boolean {
	const [reduced, setReduced] = useState(false);
	useEffect(() => {
		const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
		const fn = () => setReduced(mq.matches);
		fn();
		mq.addEventListener("change", fn);
		return () => mq.removeEventListener("change", fn);
	}, []);
	return reduced;
}

export function useDarkMode(): boolean {
	const [dark, setDark] = useState(false);
	useEffect(() => {
		const mq = window.matchMedia("(prefers-color-scheme: dark)");
		const fn = () => setDark(mq.matches);
		fn();
		mq.addEventListener("change", fn);
		return () => mq.removeEventListener("change", fn);
	}, []);
	return dark;
}

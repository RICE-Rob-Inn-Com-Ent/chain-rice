"use client";

// TODO:
// [ ] R3F Canvas: antialias, powerPreference; camera from NEXT_PUBLIC_THREE_CAMERA_POS; frameloop demand — https://docs.pmnd.rs/react-three-fiber/api/canvas
// [ ] r3f-perf dev — https://github.com/utsuboco/r3f-perf
//
import { Canvas } from "@react-three/fiber";
import { PerformanceMonitor, Preload } from "@react-three/drei";
import type { ReactNode } from "react";
import { Suspense } from "react";
import { cn } from "@/browser/lib/cn";

export type SceneProps = {
	camera?: "perspective" | "orthographic";
	shadows?: boolean;
	environment?: ReactNode;
	background?: string;
	fog?: boolean;
	dpr?: [number, number];
	performance?: boolean;
	children?: ReactNode;
	className?: string;
};

export function Scene({
	camera = "perspective",
	shadows,
	environment,
	background = "#0a0a0a",
	fog,
	dpr = [1, 2],
	performance = true,
	children,
	className,
}: SceneProps) {
	return (
		<div className={cn("h-[480px] w-full", className)}>
			<Canvas
				shadows={shadows}
				dpr={dpr}
				gl={{ antialias: true }}
				camera={camera === "orthographic" ? undefined : { position: [3, 3, 3], fov: 50 }}
			>
				{background ? <color attach="background" args={[background]} /> : null}
				{fog ? <fog attach="fog" args={[background, 5, 25]} /> : null}
				{performance ? (
					<PerformanceMonitor onDecline={() => {
						/* downgrade quality */
					}} />
				) : null}
				<Suspense fallback={null}>
					{environment}
					{children}
					<Preload all />
				</Suspense>
			</Canvas>
		</div>
	);
}

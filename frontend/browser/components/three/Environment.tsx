"use client";

// TODO:
// [ ] drei Environment preset from NEXT_PUBLIC_THREE_ENV_PRESET; HDRI Suspense — https://github.com/pmndrs/drei#environment
//
import { Environment as DreiEnv } from "@react-three/drei";
import { cn } from "@/browser/lib/cn";

export type RiceEnvironmentProps = {
	preset?: "city" | "sunset" | "dawn" | "night" | "warehouse" | "forest" | "studio";
	background?: boolean;
	blur?: number;
	intensity?: number;
	files?: string | string[];
	className?: string;
};

export function Environment({ preset = "city", background, blur = 0.6, intensity = 1, files, className }: RiceEnvironmentProps) {
	return (
		<div className={cn(className)}>
			<DreiEnv
				preset={preset}
				background={background}
				blur={blur}
				environmentIntensity={intensity}
				files={files}
			/>
		</div>
	);
}

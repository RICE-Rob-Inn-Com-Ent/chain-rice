"use client";

// TODO:
// [ ] useGLTF(url) Suspense; url from props — https://github.com/pmndrs/drei#usegltf
// [ ] useAnimations play by name — https://threejs.org/docs/#manual/en/introduction/Animation-system
//
import { useAnimations, useGLTF } from "@react-three/drei";
import { useEffect, useRef } from "react";
import type { Group } from "three";

export type ModelProps = {
	url: string;
	position?: [number, number, number];
	rotation?: [number, number, number];
	scale?: [number, number, number];
	animations?: boolean;
	lod?: boolean;
	castShadow?: boolean;
	receiveShadow?: boolean;
	onLoad?: () => void;
	onClick?: () => void;
	className?: string;
};

export function Model({
	url,
	position = [0, 0, 0],
	rotation = [0, 0, 0],
	scale = [1, 1, 1],
	animations,
	lod: _lod,
	castShadow,
	receiveShadow,
	onLoad,
	onClick,
}: ModelProps) {
	const group = useRef<Group>(null);
	const { scene, animations: clips } = useGLTF(url);
	const { actions } = useAnimations(clips, group);

	useEffect(() => {
		onLoad?.();
	}, [onLoad]);

	useEffect(() => {
		if (!animations) return;
		actions[Object.keys(actions)[0]]?.play();
	}, [actions, animations]);

	return (
		<group
			ref={group}
			position={position}
			rotation={rotation}
			scale={scale}
			onClick={onClick}
			castShadow={castShadow}
			receiveShadow={receiveShadow}
		>
			<primitive object={scene} />
		</group>
	);
}

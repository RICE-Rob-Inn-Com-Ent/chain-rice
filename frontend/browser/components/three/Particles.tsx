"use client";

// TODO:
// [ ] GPU particles BufferGeometry; count prop; audioData uniform — https://threejs.org/docs/#api/en/core/BufferGeometry
//
import { useMemo, useRef } from "react";
import { type Points, BufferGeometry, Float32BufferAttribute } from "three";
import { useFrame } from "@react-three/fiber";
export type ParticlesProps = {
	count?: number;
	spread?: number;
	colors?: string[];
	size?: number;
	speed?: number;
	shape?: "sphere" | "box" | "ring";
	texture?: string;
	opacity?: number;
	blending?: "normal" | "additive";
};

export function Particles({
	count = 400,
	spread = 4,
	colors = ["#88ccff"],
	size = 0.05,
	speed = 0.4,
	shape = "sphere",
	opacity = 0.6,
	blending = "additive",
}: ParticlesProps) {
	const ref = useRef<Points>(null);
	const geom = useMemo(() => {
		const g = new BufferGeometry();
		const positions = new Float32Array(count * 3);
		for (let i = 0; i < count; i++) {
			let x = 0;
			let y = 0;
			let z = 0;
			if (shape === "sphere") {
				const r = Math.random() * spread;
				const th = Math.random() * Math.PI * 2;
				const ph = Math.acos(2 * Math.random() - 1);
				x = r * Math.sin(ph) * Math.cos(th);
				y = r * Math.sin(ph) * Math.sin(th);
				z = r * Math.cos(ph);
			} else if (shape === "box") {
				x = (Math.random() - 0.5) * spread;
				y = (Math.random() - 0.5) * spread;
				z = (Math.random() - 0.5) * spread;
			} else {
				const r = spread * 0.5 + Math.random() * 0.2;
				const a = Math.random() * Math.PI * 2;
				x = Math.cos(a) * r;
				y = (Math.random() - 0.5) * 0.2;
				z = Math.sin(a) * r;
			}
			positions[i * 3] = x;
			positions[i * 3 + 1] = y;
			positions[i * 3 + 2] = z;
		}
		g.setAttribute("position", new Float32BufferAttribute(positions, 3));
		return g;
	}, [count, spread, shape]);

	useFrame((_, delta) => {
		if (ref.current) ref.current.rotation.y += delta * speed * 0.05;
	});

	return (
		<points ref={ref} geometry={geom}>
			<pointsMaterial
				color={colors[0]}
				size={size}
				transparent
				opacity={opacity}
				depthWrite={false}
				blending={blending === "additive" ? 2 /* AdditiveBlending */ : 0}
			/>
		</points>
	);
}

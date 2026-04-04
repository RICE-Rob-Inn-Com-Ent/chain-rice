"use client";

// TODO:
// [ ] GLSL component: uniforms time, resolution, audioData; useFrame — https://threejs.org/docs/#api/en/materials/ShaderMaterial
// [ ] HMR for shader strings
//
import { useMemo } from "react";
import * as THREE from "three";
import type { MeshProps } from "@react-three/fiber";

export type ShaderProps = {
	vertexShader?: string;
	fragmentShader?: string;
	uniforms?: Record<string, THREE.IUniform>;
	transparent?: boolean;
	wireframe?: boolean;
	side?: THREE.Side;
	children?: React.ReactNode;
} & MeshProps;

const defaultVertex = `
  void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
`;

const defaultFragment = `
  uniform float uTime;
  void main() {
    gl_FragColor = vec4(0.2 + 0.5 * sin(uTime), 0.15, 0.35, 1.0);
  }
`;

export function Shader({
	vertexShader = defaultVertex,
	fragmentShader = defaultFragment,
	uniforms,
	transparent,
	wireframe,
	side = THREE.FrontSide,
	children,
	...mesh
}: ShaderProps) {
	const material = useMemo(
		() =>
			new THREE.ShaderMaterial({
				vertexShader,
				fragmentShader,
				uniforms: uniforms ?? { uTime: { value: 0 } },
				transparent,
				wireframe,
				side,
			}),
		[vertexShader, fragmentShader, uniforms, transparent, wireframe, side],
	);

	return (
		<mesh {...mesh}>
			{children ?? <boxGeometry args={[1, 1, 1]} />}
			<primitive attach="material" object={material} />
		</mesh>
	);
}

"use client";

// TODO:
// [ ] useThree, useFrame, useTexture — https://docs.pmnd.rs/react-three-fiber/api/hooks
// [ ] useUniforms / useAudioUniforms — https://threejs.org/docs/#api/en/core/Uniform
// [ ] R3F + drei — https://github.com/pmndrs/drei
//
export { useFrame, useThree } from "@react-three/fiber";
export { useTexture, useGLTF } from "@react-three/drei";

import { useThree as useFiberThree } from "@react-three/fiber";

export function useScene() {
	const { scene, camera, gl } = useFiberThree();
	return { scene, camera, renderer: gl, gl };
}

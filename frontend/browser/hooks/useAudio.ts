"use client";

// TODO:
// [ ] useAudio: play, stop, volume, muted, toggle — AudioProvider — https://tonejs.github.io/docs/
// [ ] waveform for R3F shader
//
import * as Tone from "tone";
import { useCallback, useEffect, useRef, useState } from "react";
import { createPlayer, createSynth, ensureToneStarted } from "@/browser/lib/tone";

export function usePlayer(url: string | undefined) {
	const ref = useRef<Tone.Player | null>(null);
	const [isPlaying, setIsPlaying] = useState(false);

	useEffect(() => {
		if (!url) return;
		const p = createPlayer(url);
		ref.current = p;
		return () => {
			p.dispose();
			ref.current = null;
		};
	}, [url]);

	const play = useCallback(async () => {
		const p = ref.current;
		if (!p) return;
		await ensureToneStarted();
		await p.start();
		setIsPlaying(true);
	}, []);

	const pause = useCallback(() => {
		const p = ref.current;
		if (!p) return;
		p.stop();
		setIsPlaying(false);
	}, []);

	const stop = useCallback(() => {
		const p = ref.current;
		if (!p) return;
		p.stop();
		setIsPlaying(false);
	}, []);

	return { play, pause, stop, isPlaying };
}

export function useSynth(type: "synth" | "amsynth" | "fmsynth" = "synth") {
	const ref = useRef<Tone.PolySynth | null>(null);

	useEffect(() => {
		const s = createSynth(type);
		ref.current = s;
		return () => {
			s.dispose();
			ref.current = null;
		};
	}, [type]);

	const play = useCallback(async (note: string) => {
		const s = ref.current;
		if (!s) return;
		await ensureToneStarted();
		s.triggerAttackRelease(note, "8n");
	}, []);

	const release = useCallback(() => {
		ref.current?.releaseAll();
	}, []);

	const setVolume = useCallback((db: number) => {
		if (ref.current) ref.current.volume.value = db;
	}, []);

	return { play, release, setVolume };
}

export function useVisualizer(analyser: AnalyserNode | null) {
	const [data, setData] = useState<Float32Array>(() => new Float32Array(0));

	useEffect(() => {
		if (!analyser) return;
		const buffer = new Float32Array(analyser.frequencyBinCount);
		let raf = 0;
		const tick = () => {
			analyser.getFloatFrequencyData(buffer);
			setData(new Float32Array(buffer));
			raf = requestAnimationFrame(tick);
		};
		raf = requestAnimationFrame(tick);
		return () => cancelAnimationFrame(raf);
	}, [analyser]);

	return data;
}

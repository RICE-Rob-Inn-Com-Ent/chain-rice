"use client";

// TODO:
// [ ] Tone context on gesture; Transport, master, analyser — https://tonejs.github.io/docs/
// [ ] mic when RICE_AUDIO_INPUT=true
//
import {
	createContext,
	useCallback,
	useContext,
	useMemo,
	useRef,
	useState,
	type ReactNode,
} from "react";
import * as Tone from "tone";
import { ensureToneStarted } from "@/browser/lib/tone";

type AudioContextValue = {
	audioContext: AudioContext | null;
	ready: boolean;
	start: () => Promise<void>;
};

const AudioCtx = createContext<AudioContextValue | null>(null);

export type AudioProviderProps = {
	children: ReactNode;
};

export function AudioProvider({ children }: AudioProviderProps) {
	const [ready, setReady] = useState(false);
	const ctxRef = useRef<AudioContext | null>(null);

	const start = useCallback(async () => {
		await ensureToneStarted();
		ctxRef.current = Tone.getContext().rawContext as AudioContext;
		setReady(true);
	}, []);

	const value = useMemo(
		() => ({
			audioContext: ctxRef.current,
			ready,
			start,
		}),
		[ready, start],
	);

	return <AudioCtx.Provider value={value}>{children}</AudioCtx.Provider>;
}

export function useAudioContext(): AudioContextValue {
	const ctx = useContext(AudioCtx);
	if (!ctx) {
		throw new Error("useAudioContext must be used within AudioProvider");
	}
	return ctx;
}

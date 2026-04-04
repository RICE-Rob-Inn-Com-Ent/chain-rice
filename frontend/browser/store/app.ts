// TODO:
// [ ] version, initialized, error — Zustand — https://docs.pmnd.rs/zustand/guides/typescript
// [ ] initialize(), setError()
//
import { create } from "zustand";

export type AppSettings = Record<string, unknown>;

type AppState = {
	locale: string;
	isLoading: boolean;
	error: Error | null;
	settings: AppSettings;
	setLocale: (locale: string) => void;
	setLoading: (loading: boolean) => void;
	setError: (error: Error | null) => void;
	setSettings: (settings: AppSettings) => void;
	patchSettings: (patch: AppSettings) => void;
};

export const useAppStore = create<AppState>((set, get) => ({
	locale: "en",
	isLoading: false,
	error: null,
	settings: {},
	setLocale: (locale) => set({ locale }),
	setLoading: (isLoading) => set({ isLoading }),
	setError: (error) => set({ error }),
	setSettings: (settings) => set({ settings }),
	patchSettings: (patch) =>
		set({
			settings: { ...get().settings, ...patch },
		}),
}));

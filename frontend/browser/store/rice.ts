// TODO:
// [ ] activeProject, cookStatus, cookErrors, modelStatus — https://docs.pmnd.rs/zustand
// [ ] startCook NATS cook.reload.{project}; stopCook; setModelStatus
//
import { create } from "zustand";

type RiceRuntimeState = {
	values: Record<string, unknown>;
	set: (key: string, value: unknown) => void;
	get: (key: string) => unknown;
	reset: () => void;
	hydrate: (data: Record<string, unknown>) => void;
};

export const useRiceStore = create<RiceRuntimeState>((set, get) => ({
	values: {},
	set: (key, value) =>
		set((s) => ({
			values: { ...s.values, [key]: value },
		})),
	get: (key) => get().values[key],
	reset: () => set({ values: {} }),
	hydrate: (data) =>
		set((s) => ({
			values: { ...s.values, ...data },
		})),
}));

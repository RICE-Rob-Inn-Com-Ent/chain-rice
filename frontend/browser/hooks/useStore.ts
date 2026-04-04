"use client";

// TODO:
// [ ] selectors: useAppStore, useAuthStore, useUIStore, useRiceStore — https://docs.pmnd.rs/zustand/guides/typescript
// [ ] persist auth/ui slices — https://docs.pmnd.rs/zustand/integrations/persisting-store-data
//
import { createStore } from "zustand/vanilla";
import { useStore as useZustand } from "zustand/react";
import { useShallow } from "zustand/react/shallow";
import type { StoreApi } from "zustand/vanilla";

export function createRiceStore<T>(initialState: T): StoreApi<T> {
	return createStore<T>(() => initialState);
}

export function useStore<T, U>(store: StoreApi<T>, selector: (state: T) => U): U {
	return useZustand(store, useShallow(selector));
}

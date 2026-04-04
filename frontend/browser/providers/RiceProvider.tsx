"use client";

// TODO:
// [ ] Phoenix cook.reload.{project}; expose cookStatus, errors, modelStatus
// [ ] on reload invalidate TanStack cache — https://tanstack.com/query/latest/docs/reference/QueryClient#queryclientinvalidatequeries
//
import { useQuery, useQueryClient } from "@tanstack/react-query";
import {
	createContext,
	useCallback,
	useContext,
	useEffect,
	useMemo,
	type ReactNode,
} from "react";
import { queryKeys } from "@/browser/lib/query";
import { useRiceStore } from "@/browser/store/rice";

export const RICE_QUERY_ROOT = queryKeys.rice();

export function riceQueryKey(key: string) {
	return queryKeys.riceValue(key);
}

async function fetchRemoteRice(key: string): Promise<unknown> {
	const base = process.env.NEXT_PUBLIC_SMITH_URL;
	if (!base) return null;
	if (key.startsWith("db.")) {
		const path = key.slice(3);
		const res = await fetch(`${base}/v1/rice/db/${encodeURIComponent(path)}`, {
			credentials: "include",
		});
		if (!res.ok) throw new Error(String(res.status));
		return res.json();
	}
	if (key.startsWith("ai.")) {
		const res = await fetch(`${base}/v1/rice/ai`, {
			method: "POST",
			headers: { "Content-Type": "application/json" },
			body: JSON.stringify({ key }),
			credentials: "include",
		});
		if (!res.ok) throw new Error(String(res.status));
		return res.json();
	}
	return null;
}

export type RiceContextValue = {
	get: (key: string) => unknown | null;
	prefetch: (key: string) => Promise<void>;
};

const RiceContext = createContext<RiceContextValue | null>(null);

export type RiceProviderProps = {
	children: ReactNode;
};

export function RiceProvider({ children }: RiceProviderProps) {
	const qc = useQueryClient();

	const get = useCallback(
		(key: string): unknown | null => {
			const values = useRiceStore.getState().values;
			if (Object.prototype.hasOwnProperty.call(values, key)) {
				return values[key] as unknown;
			}
			const cached = qc.getQueryData(riceQueryKey(key));
			if (cached !== undefined) return cached as unknown;
			return null;
		},
		[qc],
	);

	const prefetch = useCallback(
		async (key: string) => {
			if (key.startsWith("db.") || key.startsWith("ai.")) {
				await qc.prefetchQuery({
					queryKey: riceQueryKey(key),
					queryFn: () => fetchRemoteRice(key),
				});
			}
		},
		[qc],
	);

	useEffect(() => {
		const onInvalidate = () => {
			void qc.invalidateQueries({ queryKey: [...RICE_QUERY_ROOT] });
		};
		if (typeof window !== "undefined") {
			window.addEventListener("rice:update", onInvalidate);
		}
		return () => {
			if (typeof window !== "undefined") {
				window.removeEventListener("rice:update", onInvalidate);
			}
		};
	}, [qc]);

	const value = useMemo(() => ({ get, prefetch }), [get, prefetch]);

	return <RiceContext.Provider value={value}>{children}</RiceContext.Provider>;
}

export function useRice(): RiceContextValue {
	const ctx = useContext(RiceContext);
	if (!ctx) {
		throw new Error("useRice must be used within RiceProvider");
	}
	return ctx;
}

/** Subscribe to remote rice keys (`db.*`, `ai.*`) with TanStack Query + hot invalidation. */
export function useRiceRemote(key: string) {
	return useQuery({
		queryKey: riceQueryKey(key),
		queryFn: () => fetchRemoteRice(key),
		enabled: key.startsWith("db.") || key.startsWith("ai."),
	});
}

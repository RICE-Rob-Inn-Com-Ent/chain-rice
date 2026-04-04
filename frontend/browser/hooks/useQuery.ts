"use client";

// TODO:
// [ ] useRiceQuery / useRiceMutation wrappers + error boundary — https://tanstack.com/query/latest/docs/framework/react/reference/useQuery
// [ ] useSuspenseQuery — https://tanstack.com/query/latest/docs/framework/react/reference/useSuspenseQuery
// [ ] useInfiniteRiceQuery cursor pagination — https://tanstack.com/query/latest/docs/framework/react/reference/useInfiniteQuery
//
import {
	type QueryKey,
	type UseQueryOptions,
	type UseQueryResult,
	useQuery as useTanstackQuery,
} from "@tanstack/react-query";
import { useEffect, useRef } from "react";
import { toast } from "sonner";

export type UseRiceQueryOptions<TQueryFnData, TError> = Omit<
	UseQueryOptions<TQueryFnData, TError>,
	"queryKey" | "queryFn"
> & {
	queryKey: QueryKey;
	queryFn: () => Promise<TQueryFnData>;
	suppressErrorToast?: boolean;
};

/**
 * TanStack Query with optional error toast (targets 60 FPS — avoid heavy work in render).
 */
export function useQuery<TQueryFnData = unknown, TError = Error>(
	options: UseRiceQueryOptions<TQueryFnData, TError>,
): UseQueryResult<TQueryFnData, TError> {
	const { suppressErrorToast, ...rest } = options;
	const q = useTanstackQuery(rest);
	const toasted = useRef(false);

	useEffect(() => {
		if (!q.isError || !q.error || suppressErrorToast) {
			toasted.current = false;
			return;
		}
		if (toasted.current) return;
		toasted.current = true;
		const message = q.error instanceof Error ? q.error.message : "Request failed";
		toast.error(message);
	}, [q.isError, q.error, suppressErrorToast]);

	return q;
}

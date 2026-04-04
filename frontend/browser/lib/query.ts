// TODO:
// [ ] QueryClient: staleTime/gcTime from NEXT_PUBLIC_* env; retry exponential — https://tanstack.com/query/latest/docs/reference/QueryClient
// [ ] riceKeys factory — https://tanstack.com/query/latest/docs/framework/react/guides/query-keys
// [ ] optimistic useMutation onMutate/rollback — https://tanstack.com/query/latest/docs/framework/react/guides/optimistic-updates
// [ ] useInfiniteQuery + cursor from kit/page.go — https://tanstack.com/query/latest/docs/framework/react/guides/infinite-queries
//
import { QueryClient } from "@tanstack/react-query";

export const queryClient: QueryClient = new QueryClient({
	defaultOptions: {
		queries: {
			staleTime: 60_000,
			gcTime: 5 * 60_000,
			retry: 2,
			refetchOnWindowFocus: false,
		},
	},
});

export const queryKeys = {
	users: {
		all: ["users"] as const,
		detail: (id: string) => ["users", id] as const,
	},
	posts: {
		all: ["posts"] as const,
		detail: (id: string) => ["posts", id] as const,
	},
	rice: () => ["rice"] as const,
	riceValue: (key: string) => ["rice", key] as const,
} as const;

export async function prefetchQuery<T>(
	qc: QueryClient,
	key: readonly unknown[],
	fetcher: () => Promise<T>,
): Promise<void> {
	await qc.prefetchQuery({ queryKey: key, queryFn: fetcher });
}

export async function invalidateAll(qc: QueryClient): Promise<void> {
	await qc.invalidateQueries();
}

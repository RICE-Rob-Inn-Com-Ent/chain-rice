"use client";

// TODO:
// [ ] useProto<T> Connect client lifecycle — https://connectrpc.com/docs/web/using-clients
// [ ] useProtoStream server streaming — https://connectrpc.com/docs/web/streaming
//
import { ConnectError } from "@connectrpc/connect";
import { useMutation, useQuery as useTanstackQuery } from "@tanstack/react-query";

export function humanizeConnectError(err: unknown): string {
	if (err instanceof ConnectError) {
		return err.rawMessage || err.message;
	}
	if (err instanceof Error) return err.message;
	return "Unknown error";
}

export type ProtoQueryOptions<TData> = {
	queryKey: unknown[];
	queryFn: () => Promise<TData>;
	enabled?: boolean;
};

/** Typed ConnectRPC query — pass `queryFn` that calls your generated client method. */
export function useProtoQuery<TData>(options: ProtoQueryOptions<TData>) {
	return useTanstackQuery({
		queryKey: options.queryKey,
		queryFn: options.queryFn,
		enabled: options.enabled ?? true,
	});
}

/** Typed ConnectRPC mutation — pass async function wrapping generated client unary call. */
export function useProtoMutation<TReq, TRes>(fn: (req: TReq) => Promise<TRes>) {
	return useMutation({
		mutationFn: async (req: TReq) => {
			try {
				return await fn(req);
			} catch (e) {
				throw new Error(humanizeConnectError(e));
			}
		},
	});
}

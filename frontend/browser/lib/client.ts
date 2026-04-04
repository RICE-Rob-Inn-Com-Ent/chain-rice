// TODO:
// [ ] ConnectRPC: createConnectTransport({ baseUrl: env.apiUrl }); typed clients from gen/ — https://connectrpc.com/docs/web/getting-started
// [ ] factory createClient<T>(service); retry + OTel — https://opentelemetry.io/docs/languages/js/
// [ ] auth interceptor: PASETO from Zustand — cookie/httpOnly strategy from env — https://docs.pmnd.rs/zustand
// [ ] errors: ConnectError → RiceError; unauthenticated → login — https://github.com/connectrpc/connect-es/blob/main/MIGRATING.md
// [ ] dedup: stateless client; TanStack Query dedup — https://tanstack.com/query/latest/docs/framework/react/guides/request-waterfalls
//
import { createClient } from "@connectrpc/connect";
import { createConnectTransport } from "@connectrpc/connect-web";
import type { DescService } from "@bufbuild/protobuf";

export type SmithTransportOptions = {
	baseUrl?: string;
	credentials?: RequestCredentials;
};

function defaultBaseUrl(): string {
	return process.env.NEXT_PUBLIC_SMITH_URL ?? "";
}

export function createSmithTransport(options: SmithTransportOptions = {}) {
	const baseUrl = options.baseUrl ?? defaultBaseUrl();
	const credentials = options.credentials ?? "same-origin";
	return createConnectTransport({
		baseUrl,
		useBinaryFormat: true,
		fetch: (input, init) => globalThis.fetch(input, { ...init, credentials }),
	});
}

let transportSingleton: ReturnType<typeof createConnectTransport> | null = null;

export function getSmithTransport(options?: SmithTransportOptions) {
	if (!transportSingleton) {
		transportSingleton = createSmithTransport(options);
	}
	return transportSingleton;
}

export function createSmithClient<T extends DescService>(service: T, options?: SmithTransportOptions) {
	return createClient(service, getSmithTransport(options));
}

export type SmithServiceClient<T extends DescService> = ReturnType<typeof createSmithClient<T>>;

// TODO:
// [ ] tighten Phoenix JS types: Socket, Channel, Push payloads from gen/ — https://hexdocs.pm/phoenix/js/
//
declare module "phoenix" {
	export class Socket {
		constructor(endPoint: string, opts?: Record<string, unknown>);
		connect(): void;
		disconnect(callback?: () => void, code?: number, reason?: string): void;
		channel(topic: string, chanParams?: Record<string, unknown>): Channel;
	}

	export class Channel {
		on(event: string, callback: (payload?: unknown) => void): number;
		off(event: string, ref: number): void;
		push(event: string, payload: Record<string, unknown>, timeout?: number): Push;
		join(timeout?: number): Push;
		leave(timeout?: number): Push;
	}

	export class Push {
		receive(status: string, callback: (resp?: unknown) => void): Push;
	}
}

"use client";

// TODO:
// [ ] Phoenix useSocket(topic): channel, connected, push — ws from env.wsUrl + PASETO — https://hexdocs.pm/phoenix/js/
// [ ] join/leave lifecycle; reconnect backoff
// [ ] typed events via gen/ proto
//
import { Channel, Socket } from "phoenix";
import { useCallback, useEffect, useRef } from "react";

export type SocketHandle = {
	socket: Socket;
	channel: (topic: string, params?: Record<string, unknown>) => Channel;
};

const backoff = (attempt: number) => Math.min(30_000, 1000 * 2 ** attempt);

export function connect(url: string, token?: string): SocketHandle {
	const socket = new Socket(url, {
		params: { token: token ?? "" },
		reconnectAfterMs: (tries: number) => backoff(tries),
	});

	socket.connect();

	return {
		socket,
		channel: (topic, params) => socket.channel(topic, params ?? {}),
	};
}

export function subscribe(channel: Channel, event: string, handler: (payload: unknown) => void): () => void {
	const ref = channel.on(event, (payload: unknown) => {
		handler(payload);
	});
	return () => {
		channel.off(event, ref);
	};
}

export function push<T = unknown>(
	channel: Channel,
	event: string,
	payload: Record<string, unknown>,
): Promise<T> {
	return new Promise((resolve, reject) => {
		channel
			.push(event, payload)
			.receive("ok", (resp: unknown) => resolve(resp as T))
			.receive("error", (resp: unknown) => reject(resp))
			.receive("timeout", () => reject(new Error("push timeout")));
	});
}

export function usePhoenixSocket(url: string | undefined, token?: string) {
	const ref = useRef<Socket | null>(null);

	useEffect(() => {
		if (!url) return;
		const { socket } = connect(url, token);
		ref.current = socket;
		return () => {
			socket.disconnect();
			ref.current = null;
		};
	}, [url, token]);

	const join = useCallback((topic: string, params?: Record<string, unknown>) => {
		if (!ref.current) throw new Error("Socket not connected");
		return ref.current.channel(topic, params ?? {});
	}, []);

	return { join };
}

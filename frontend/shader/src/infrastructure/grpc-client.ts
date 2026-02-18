/**
 * ConnectRPC transport factory with interceptors for logging and header propagation.
 * Uses HTTP/2 when available via @connectrpc/connect-node.
 */
import { AsyncLocalStorage } from "node:async_hooks";
import {
  createConnectTransport,
  type Interceptor,
  type Transport,
} from "@connectrpc/connect-node";
import type { ServiceType } from "@bufbuild/protobuf";
import { createPromiseClient, type PromiseClient } from "@connectrpc/connect";

/** Request context passed by the BFF so gRPC calls can forward auth/tracing. */
export interface GrpcRequestContext {
  headers: Headers;
}

const contextStorage = new AsyncLocalStorage<GrpcRequestContext>();

/**
 * Run a function with the current request context (set by HTTP layer).
 * Interceptors use this to forward Authorization and trace headers to gRPC.
 * Supports sync and async callbacks; await the result when calling gRPC.
 */
export function runWithGrpcContext<T>(
  ctx: GrpcRequestContext,
  fn: () => T | Promise<T>,
): T | Promise<T> {
  return contextStorage.run(ctx, fn) as T | Promise<T>;
}

function getContext(): GrpcRequestContext | undefined {
  return contextStorage.getStore();
}

/** Interceptor: forward Authorization, X-Request-Id, and other propagation headers to the gRPC request. */
const headerPropagationInterceptor: Interceptor = (next) => async (req) => {
  const ctx = getContext();
  if (ctx?.headers) {
    const forward = ["authorization", "x-request-id", "x-trace-id", "x-span-id"];
    for (const key of forward) {
      const value = ctx.headers.get(key);
      if (value) req.header.set(key, value);
    }
  }
  return next(req);
};

/** Interceptor: log request URL and method (and optionally errors). */
const loggingInterceptor: Interceptor = (next) => async (req) => {
  const url = req.url;
  const method = req.method.name;
  const start = Date.now();
  try {
    const res = await next(req);
    console.debug(`[grpc] ${method} ${url} ${Date.now() - start}ms`);
    return res;
  } catch (e) {
    console.error(`[grpc] ${method} ${url} error after ${Date.now() - start}ms`, e);
    throw e;
  }
};

export interface GrpcClientOptions {
  baseUrl: string;
  /** If true, use HTTP/2 (required for full gRPC; use "1.1" for Connect protocol over HTTP/1.1). */
  httpVersion?: "1.1" | "2";
}

/**
 * Create a Connect transport with logging and header-propagation interceptors.
 * Use this to build promise clients for each service.
 */
export function createGrpcTransport(options: GrpcClientOptions): Transport {
  const { baseUrl, httpVersion = "2" } = options;
  return createConnectTransport({
    baseUrl,
    httpVersion,
    interceptors: [headerPropagationInterceptor, loggingInterceptor],
  });
}

/**
 * Create a typed Promise client for a Connect service.
 * Call this inside a request handler after runWithGrpcContext so interceptors see the request headers.
 */
export function createGrpcClient<T extends ServiceType>(
  service: T,
  transport: Transport,
): PromiseClient<T> {
  return createPromiseClient(service, transport);
}

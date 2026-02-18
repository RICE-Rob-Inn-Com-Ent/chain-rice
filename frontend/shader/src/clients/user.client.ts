/**
 * User service gRPC client factory.
 * Uses shared transport from config; call inside runWithGrpcContext so headers are propagated.
 */
import { createGrpcClient, createGrpcTransport } from "../infrastructure/grpc-client.js";
import { UserService } from "../gen/user/v1/user_connect.js";
import type { PromiseClient } from "@connectrpc/connect";

const transportByBaseUrl = new Map<string, ReturnType<typeof createGrpcTransport>>();

function getTransport(baseUrl: string) {
  let transport = transportByBaseUrl.get(baseUrl);
  if (!transport) {
    transport = createGrpcTransport({ baseUrl, httpVersion: "2" });
    transportByBaseUrl.set(baseUrl, transport);
  }
  return transport;
}

/**
 * Create a Promise client for UserService.
 * Use from within an HTTP handler after runWithGrpcContext(ctx, () => { ... }).
 */
export function getUserClient(baseUrl: string): PromiseClient<typeof UserService> {
  return createGrpcClient(UserService, getTransport(baseUrl));
}

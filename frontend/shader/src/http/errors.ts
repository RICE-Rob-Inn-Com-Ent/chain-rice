/**
 * Maps Connect/gRPC error codes to HTTP status codes for BFF responses.
 */
import { Code, ConnectError } from "@connectrpc/connect";

const codeToStatus: Record<Code, number> = {
  [Code.OK]: 200,
  [Code.Canceled]: 499,
  [Code.Unknown]: 500,
  [Code.InvalidArgument]: 400,
  [Code.DeadlineExceeded]: 504,
  [Code.NotFound]: 404,
  [Code.AlreadyExists]: 409,
  [Code.PermissionDenied]: 403,
  [Code.ResourceExhausted]: 429,
  [Code.FailedPrecondition]: 400,
  [Code.Aborted]: 409,
  [Code.OutOfRange]: 400,
  [Code.Unimplemented]: 501,
  [Code.Internal]: 500,
  [Code.Unavailable]: 503,
  [Code.DataLoss]: 500,
  [Code.Unauthenticated]: 401,
};

export function connectErrorToHttpStatus(error: ConnectError): number {
  return codeToStatus[error.code] ?? 500;
}

export function isConnectError(value: unknown): value is ConnectError {
  return value instanceof ConnectError;
}

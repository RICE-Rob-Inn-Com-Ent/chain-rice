/**
 * User orchestration: calls Go UserService via gRPC and maps to BFF/Frontend shape.
 */
import { getUserClient } from "../clients/user.client.js";
import type { User } from "../gen/user/v1/user_pb.js";

/** Frontend-facing user shape (e.g. camelCase, optional fields). */
export interface UserDto {
  id: string;
  email: string;
  displayName: string;
  createdAt: string;
}

function mapUserToDto(grpcUser: User): UserDto {
  return {
    id: grpcUser.id,
    email: grpcUser.email,
    displayName: grpcUser.displayName,
    createdAt: grpcUser.createdAt,
  };
}

/**
 * Fetch user by ID from the Go UserService.
 * Call inside runWithGrpcContext so auth/trace headers are forwarded.
 */
export async function getUserById(
  userId: string,
  userServiceUrl: string,
): Promise<UserDto> {
  const client = getUserClient(userServiceUrl);
  const user = await client.getUser({ id: userId });
  return mapUserToDto(user);
}

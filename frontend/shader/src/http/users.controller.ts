/**
 * Users HTTP controller: validates input (Valibot), calls service, maps gRPC errors to HTTP.
 */
import { Elysia } from "elysia";
import * as v from "valibot";
import { runWithGrpcContext } from "../infrastructure/grpc-client.js";
import { getUserById } from "../services/user.service.js";
import {
  connectErrorToHttpStatus,
  isConnectError,
} from "./errors.js";
import { loadEnv } from "../config/index.js";

const pathParamsSchema = v.object({
  id: v.pipe(
    v.string(),
    v.minLength(1, "id is required"),
    v.maxLength(128, "id too long"),
  ),
});

export const usersController = new Elysia({ prefix: "/users" })
  .derive(() => ({ env: loadEnv() }))
  .get(
    "/:id",
    async ({ params, env, set, request }) => {
      const parsed = v.safeParse(pathParamsSchema, params);
      if (!parsed.success) {
        set.status = 400;
        return { error: "Validation failed", issues: parsed.issues };
      }
      const { id } = parsed.output;

      try {
        const user = await runWithGrpcContext(
          { headers: request.headers },
          async () => getUserById(id, env.USER_SERVICE_URL),
        );
        return user;
      } catch (e) {
        if (isConnectError(e)) {
          set.status = connectErrorToHttpStatus(e);
          return { error: e.message, code: e.code };
        }
        set.status = 500;
        return { error: "Internal server error" };
      }
    },
    {
      detail: {
        summary: "Get user by ID",
        description: "Returns a single user from the Go UserService via gRPC.",
        tags: ["Users"],
        responses: {
          200: { description: "User found" },
          400: { description: "Invalid path parameters" },
          404: { description: "User not found" },
          500: { description: "Internal or upstream error" },
        },
      },
    },
  );

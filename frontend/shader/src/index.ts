/**
 * @rice/node — API Gateway / BFF (Backend for Frontend)
 * Runtime: Bun | Framework: ElysiaJS | Internal: ConnectRPC (gRPC-Web)
 */
import { Elysia } from "elysia";
import { swagger } from "@elysiajs/swagger";
import { cors } from "@elysiajs/cors";
import { staticPlugin } from "@elysiajs/static";
import { loadEnv } from "./config/index.js";
import { usersController } from "./http/index.js";

const env = loadEnv();

const app = new Elysia()
  .use(
    swagger({
      documentation: {
        info: {
          title: "Rice BFF API",
          version: "1.0.0",
          description:
            "Backend for Frontend — validates HTTP input, orchestrates Go/Python microservices via gRPC-Web (ConnectRPC).",
        },
        tags: [
          { name: "Users", description: "User resources from Go UserService" },
        ],
      },
      path: "/docs",
    }),
  )
  .use(cors())
  .use(staticPlugin({ assets: "public", prefix: "/" }))
  .use(usersController)
  .get("/health", () => ({ status: "ok", ts: new Date().toISOString() }))
  .listen(env.PORT);

console.info(
  `[rice/node] BFF listening on http://localhost:${app.server?.port} | Swagger: http://localhost:${app.server?.port}/docs`,
);

export type App = typeof app;

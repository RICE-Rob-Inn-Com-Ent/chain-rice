import { RouteInterface } from "@/types/interfaces/RouteInterface";
import { authRoutes } from "./authRoutes";
import { docsRoutes } from "./docsRoutes";

export const appRoutes: RouteInterface[] = [
  {
    path: "/docs",
    label: "Docs",
    slug: "docs",
    children: docsRoutes,
  },
  {
    path: "/auth",
    label: "Auth",
    slug: "auth",
    children: authRoutes,
  },
];

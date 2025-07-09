import React from "react";
import { RouteInterface } from "@/types/interfaces/RouteInterface";

const Login = React.lazy(() =>
  import("@/layouts/modules/Login").then((module) => ({
    default: module.Login,
  }))
);
const Register = React.lazy(() =>
  import("@/layouts/modules/Register").then((module) => ({
    default: module.Register,
  }))
);

export const authRoutes: RouteInterface[] = [
  {
    path: "/login",
    label: "Login",
    slug: "login",
    element: React.createElement(Login),
  },
  {
    path: "/register",
    label: "Register",
    slug: "register",
    element: React.createElement(Register),
  },
];

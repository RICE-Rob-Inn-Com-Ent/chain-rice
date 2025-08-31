import { lazy } from "react";

export const UI = {
  Click: lazy(() => import("./Click").then((ui) => ({ default: ui.Click }))),
  Container: lazy(() =>
    import("./Container").then((ui) => ({ default: ui.Container }))
  ),
  Form: lazy(() => import("./Form").then((ui) => ({ default: ui.Form }))),
  List: lazy(() => import("./List").then((ui) => ({ default: ui.List }))),
  Media: lazy(() => import("./Media").then((ui) => ({ default: ui.Media }))),
  Text: lazy(() => import("./Text").then((ui) => ({ default: ui.Text }))),
};

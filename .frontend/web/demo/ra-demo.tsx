import React from "react";
import { createRoot } from "react-dom/client";
import Ra from "../widget/models/Ra";
import "../index.css";

const root = document.getElementById("root");
if (root) {
  createRoot(root).render(<Ra />);
}

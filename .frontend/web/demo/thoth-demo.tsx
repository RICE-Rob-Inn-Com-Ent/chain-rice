import React from "react";
import { createRoot } from "react-dom/client";
import Thoth from "../widget/models/Thoth";
import "../index.css";

const root = document.getElementById("root");
if (root) {
  createRoot(root).render(<Thoth />);
}

import React from "react";
import { createRoot } from "react-dom/client";
import Khnum from "../widget/models/Khnum";
import "../index.css";

const root = document.getElementById("root");
if (root) {
  createRoot(root).render(<Khnum />);
}


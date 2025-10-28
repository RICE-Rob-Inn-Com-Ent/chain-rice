import React from "react";
import { createRoot } from "react-dom/client";
import Bastet from "../widget/models/Bastet";
import "../index.css";

const root = document.getElementById("root");
if (root) {
  createRoot(root).render(<Bastet />);
}

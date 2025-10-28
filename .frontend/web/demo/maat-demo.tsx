import React from "react";
import { createRoot } from "react-dom/client";
import Maat from "../widget/models/Maat";
import "../index.css";

const root = document.getElementById("root");
if (root) {
  createRoot(root).render(<Maat />);
}

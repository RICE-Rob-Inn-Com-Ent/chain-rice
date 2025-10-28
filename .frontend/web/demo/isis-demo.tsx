import React from "react";
import { createRoot } from "react-dom/client";
import Isis from "../widget/models/Isis";
import "../index.css";

const root = document.getElementById("root");
if (root) {
  createRoot(root).render(<Isis />);
}


import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import App from "./App";

describe("App", () => {
  it("renders InfiniR title", () => {
    render(<App />);
    expect(screen.getByText("InfiniR")).toBeInTheDocument();
  });

  it("renders Web Platform subtitle", () => {
    render(<App />);
    expect(screen.getByText("Web Platform")).toBeInTheDocument();
  });
});

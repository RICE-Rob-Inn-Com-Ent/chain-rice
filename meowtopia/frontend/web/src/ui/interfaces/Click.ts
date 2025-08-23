import React from "react";

export interface ClickInterface extends React.HTMLAttributes<HTMLElement> {
  variant?: "button" | "link" | "icon";
  size?: "sm" | "md" | "lg";
  disabled?: boolean;
  children: React.ReactNode;
  onClick?: () => void;
}

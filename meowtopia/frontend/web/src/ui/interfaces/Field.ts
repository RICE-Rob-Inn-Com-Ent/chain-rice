import React from "react";

export interface FieldInterface extends React.HTMLAttributes<HTMLElement> {
  tag: "input" | "textarea" | "select";
  type?:
    | "text"
    | "password"
    | "email"
    | "number"
    | "radio"
    | "checkbox"
    | "date"
    | "file"
    | "search"
    | "tel"
    | "url";
  role?: "default" | "error" | "success";
  size?: "sm" | "md" | "lg";
  children?: React.ReactNode;
  icon?: string;
  placeholder?: string;
  value?: string;
  checked?: boolean;
  onChange?:
    | React.ChangeEventHandler<HTMLInputElement>
    | React.ChangeEventHandler<HTMLTextAreaElement>
    | React.ChangeEventHandler<HTMLSelectElement>;
}

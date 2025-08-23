import React from "react";
import { TextConfig } from "../interfaces/Text";

export const Text: React.FC<TextConfig> = ({
  tag = "span",
  variant = "body",
  children,
}) => {
  const Tag = tag;
  const variantClasses = {
    "title-1": "text-4xl font-bold tracking-tight",
    "title-2": "text-3xl font-semibold",
    "title-3": "text-2xl font-semibold",
    "subtitle": "text-xl font-medium text-gray-700",
    "body": "text-base text-gray-800",
    "caption": "text-sm text-gray-500",
    "label": "text-sm font-medium text-gray-700",
    "error": "text-sm text-red-600",
    "success": "text-sm text-green-600",
    "helper": "text-xs text-gray-400 italic",
  };
  const className = variantClasses[variant];

  return <Tag className={className}>{children}</Tag>;
};
import React from "react";

export interface ContainerConfig extends React.HTMLAttributes<HTMLElement> {
  tag?:
    | "div"
    | "form"
    | "section"
    | "article"
    | "main"
    | "aside"
    | "header"
    | "footer";
  variant?:
    | "default"
    | "form"
    | "card"
    | "section"
    | "panel"
    | "boxed"
    | "highlight"
    | "loader-small"
    | "loader-medium"
    | "loader-large"
    | "loader-global";
  children?: React.ReactNode;
}

export const Container: React.FC<ContainerConfig> = ({
  tag = "div",
  variant = "default",
  children,
  ...props
}) => {
  const Tag = tag;
  const variantClasses = {
    "default": "flex flex-row",
    "form": "flex flex-col",
    "card": "bg-green shadow-md rounded-xl p-5",
    "section": "py-8 px-4 sm:px-8",
    "panel": "bg-gray-100 p-4 rounded-md",
    "boxed": "border border-gray-200 p-4 rounded",
    "highlight": "bg-yellow-100 p-4 border-l-4 border-yellow-400",
    "loader-small": "flex items-center justify-center p-2",
    "loader-medium": "flex items-center justify-center p-4",
    "loader-large": "flex flex-col items-center justify-center p-8 space-y-4",
    "loader-global": "flex items-center justify-center min-h-screen bg-gray-100 text-gray-600",
  };
  const className = variantClasses[variant] || "";

  return <Tag className={className} {...props}>{children}</Tag>;
};

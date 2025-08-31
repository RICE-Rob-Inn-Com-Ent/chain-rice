import React from "react";

export interface ListInterface {
  tag?: "ul" | "ol" | "li" | "dl" | "dt" | "dd";
  style?: {
    className?: string;
    initial?: {
      opacity: number;
      x?: number;
      y?: number;
    };
    animate?: {
      opacity: number;
      x?: number;
      y?: number;
    };
    exit?: {
      opacity: number;
      x?: number;
      y?: number;
    };
    transition?: {
      duration: number;
    };
  };
  children?: React.ReactNode;
}

export const List: React.FC<ListInterface> = ({
  tag = "ul",
  style,
  children,
  ...props
}) => {
  const getTagClasses = (tag: string) => {
    switch (tag) {
      case "ul":
        return "space-y-2 list-disc list-inside text-gray-700 marker:text-blue-500";
      case "ol":
        return "space-y-2 list-decimal list-inside text-gray-700 marker:text-blue-500 marker:font-medium";
      case "li":
        return "text-gray-700 leading-relaxed marker:text-blue-500";
      case "dl":
        return "space-y-4";
      case "dt":
        return "text-sm font-semibold text-gray-900 uppercase tracking-wide";
      case "dd":
        return "mt-1 text-sm text-gray-700 pl-4 border-l-2 border-gray-200";
      default:
        return "space-y-2";
    }
  };

  const baseClasses = getTagClasses(tag);
  const listClasses = `${baseClasses} ${style?.className || ""}`;

  const Component = tag as React.ElementType;

  return (
    <Component
      className={listClasses}
      {...props}
    >
      {children}
    </Component>
  );
};

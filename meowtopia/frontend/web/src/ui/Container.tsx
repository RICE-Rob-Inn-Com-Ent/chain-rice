import React from "react";

export interface ContainerInterface {
  tag?:
    | "div"
    | "section"
    | "article"
    | "main"
    | "aside"
    | "nav"
    | "header"
    | "footer"
    | "table"
    | "thead"
    | "tbody"
    | "tfoot"
    | "tr"
    | "th"
    | "td"
    | "caption"
    | "col"
    | "colgroup"
    | "figure"
    | "figcaption"
    | "details"
    | "summary"
    | "dialog";
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
  className?: string;
  id?: string;
  children?: React.ReactNode;
}

export const Container: React.FC<ContainerInterface> = ({
  tag = "div",
  style,
  id,
  className,
  children,
  ...props
}) => {
  const getTagClasses = (tag: string) => {
    switch (tag) {
      case "div":
        return "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8";
      case "section":
        return "py-12 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto";
      case "article":
        return "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6";
      case "main":
        return "flex-1 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8";
      case "aside":
        return "w-64 bg-gray-50 border-r border-gray-200 p-4";
      case "nav":
        return "bg-white shadow-sm border-b border-gray-200 px-4 sm:px-6 lg:px-8";
      case "header":
        return "bg-white shadow-sm border-b border-gray-200 px-4 sm:px-6 lg:px-8 py-4";
      case "footer":
        return "bg-gray-50 border-t border-gray-200 px-4 sm:px-6 lg:px-8 py-8";
      case "table":
        return "min-w-full divide-y divide-gray-200 bg-white rounded-lg shadow-sm border border-gray-200";
      case "thead":
        return "bg-gray-50";
      case "tbody":
        return "bg-white divide-y divide-gray-200";
      case "tfoot":
        return "bg-gray-50";
      case "tr":
        return "hover:bg-gray-50 transition-colors duration-150";
      case "th":
        return "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider";
      case "td":
        return "px-6 py-4 whitespace-nowrap text-sm text-gray-900";
      case "caption":
        return "px-6 py-2 text-sm text-gray-600 bg-gray-50 border-t border-gray-200";
      case "col":
        return "";
      case "colgroup":
        return "";
      case "figure":
        return "max-w-lg mx-auto bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden";
      case "figcaption":
        return "px-4 py-3 text-sm text-gray-600 bg-gray-50 border-t border-gray-200";
      case "details":
        return "bg-white rounded-lg shadow-sm border border-gray-200 p-4";
      case "summary":
        return "cursor-pointer font-medium text-gray-900 hover:text-blue-600 transition-colors duration-150";
      case "dialog":
        return "bg-white rounded-lg shadow-xl border border-gray-200 p-6 max-w-md mx-auto";
      default:
        return "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8";
    }
  };

  const baseClasses = getTagClasses(tag);
  const containerClasses = `${baseClasses} ${style?.className || ""} ${
    className || ""
  }`.trim();

  const Component = tag as React.ElementType;

  return (
    <Component id={id} className={containerClasses} {...props}>
      {children}
    </Component>
  );
};

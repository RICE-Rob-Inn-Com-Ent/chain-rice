import React from "react";

export interface FormInterface {
  onSubmit?: (e: React.FormEvent<HTMLFormElement>) => void;
  tag?:
    | "form"
    | "label"
    | "input"
    | "textarea"
    | "select"
    | "option"
    | "fieldset"
    | "legend"
    | "output"
    | "progress"
    | "meter";
  type?:
    | "email"
    | "password"
    | "text"
    | "number"
    | "date"
    | "time"
    | "datetime-local"
    | "tel"
    | "url"
    | "search"
    | "checkbox"
    | "radio";
  placeholder?: string;
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

export const Form: React.FC<FormInterface> = ({
  tag = "form",
  onSubmit,
  style,
  children,
  type,
  placeholder,
  ...props
}) => {
  const getTagClasses = (tag: string, type?: string) => {
    switch (tag) {
      case "form":
        return "space-y-6 p-6 bg-white rounded-lg shadow-sm border border-gray-200";
      case "label":
        return "block text-sm font-medium text-gray-700 mb-2 cursor-pointer";
      case "input":
        const inputBase = "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors duration-200";
        if (type === "checkbox") {
          return "w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2 cursor-pointer";
        }
        if (type === "radio") {
          return "w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 focus:ring-blue-500 focus:ring-2 cursor-pointer";
        }
        return inputBase;
      case "textarea":
        return "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors duration-200 resize-vertical min-h-[100px]";
      case "select":
        return "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors duration-200 bg-white cursor-pointer";
      case "option":
        return "py-1 px-2 hover:bg-blue-50 cursor-pointer";
      case "fieldset":
        return "border border-gray-300 rounded-md p-4 space-y-4";
      case "legend":
        return "px-2 text-sm font-medium text-gray-700 bg-white";
      case "output":
        return "inline-block px-3 py-1 bg-gray-100 text-gray-800 rounded-md font-mono text-sm";
      case "progress":
        return "w-full h-2 bg-gray-200 rounded-full overflow-hidden";
      case "meter":
        return "w-full h-2 bg-gray-200 rounded-full overflow-hidden";
      default:
        return "";
    }
  };

  const baseClasses = getTagClasses(tag, type);
  const formClasses = `${baseClasses} ${style?.className || ""}`.trim();

  const Component = tag as React.ElementType;

  if (tag === "form" && onSubmit) {
    return (
      <form onSubmit={onSubmit} className={formClasses} {...props}>
        {children}
      </form>
    );
  }

  if (tag === "input") {
    return (
      <input
        type={type}
        placeholder={placeholder}
        className={formClasses}
        {...props}
      />
    );
  }

  if (tag === "textarea") {
    return (
      <textarea
        placeholder={placeholder}
        className={formClasses}
        {...props}
      />
    );
  }

  if (tag === "select") {
    return (
      <select className={formClasses} {...props}>
        {children}
      </select>
    );
  }

  if (tag === "progress") {
    return (
      <progress className={formClasses} {...props}>
        {children}
      </progress>
    );
  }

  if (tag === "meter") {
    return (
      <meter className={formClasses} {...props}>
        {children}
      </meter>
    );
  }

  return (
    <Component className={formClasses} {...props}>
      {children}
    </Component>
  );
};

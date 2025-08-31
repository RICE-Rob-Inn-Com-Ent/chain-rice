import React from "react";

export interface ClickInterface {
  onClick?: () => void;
  tag?: "button" | "a";
  type?: "button" | "submit" | "reset";
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
  url?: string;
  target?: string;
  children?: React.ReactNode;
}

export const Click: React.FC<ClickInterface> = ({
  onClick,
  tag = "button",
  type = "button",
  style,
  url,
  target,
  children,
  className,
  ...props
}) => {
  const getTagClasses = (tag: string, type?: string) => {
    if (tag === "button") {
      switch (type) {
        case "submit":
          return "w-full px-4 py-3 bg-blue-600 text-white font-semibold rounded-lg shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all duration-200 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed";
        case "reset":
          return "px-4 py-2 bg-gray-500 text-white font-medium rounded-md shadow-sm hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition-all duration-200 active:scale-95";
        default:
          return "px-4 py-2 bg-gray-100 text-gray-700 font-medium rounded-md shadow-sm hover:bg-gray-200 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition-all duration-200 active:scale-95 border border-gray-300";
      }
    } else if (tag === "a") {
      return "inline-flex items-center px-4 py-2 text-blue-600 font-medium rounded-md hover:text-blue-700 hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all duration-200 underline decoration-2 underline-offset-2";
    }
    return "";
  };

  const baseClasses = getTagClasses(tag, type);
  const buttonClasses = `${baseClasses} ${style?.className || ""} ${
    className || ""
  }`.trim();

  if (tag === "a" && url) {
    return (
      <a
        href={url}
        target={target}
        className={buttonClasses}
        onClick={onClick}
        {...props}
      >
        {children}
      </a>
    );
  }

  return (
    <button type={type} className={buttonClasses} onClick={onClick} {...props}>
      {children}
    </button>
  );
};

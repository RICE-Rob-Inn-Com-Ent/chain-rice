import React from "react";

export interface TextInterface {
  tag:
    | "p"
    | "span"
    | "strong"
    | "em"
    | "small"
    | "mark"
    | "code"
    | "pre"
    | "blockquote"
    | "time"
    | "u"
    | "i"
    | "b"
    | "s"
    | "sub"
    | "sup"
    | "h1"
    | "h2"
    | "h3"
    | "h4"
    | "h5"
    | "h6"
    | "q"
    | "cite"
    | "abbr"
    | "del"
    | "ins";
  style?: {
    className?: string;
  };
  id?: string;
  children?: React.ReactNode;
}

export const Text: React.FC<TextInterface> = ({
  tag,
  style,
  id,
  children,
  ...props
}) => {
  const getTagClasses = (tag: string) => {
    switch (tag) {
      case "h1":
        return "text-4xl font-bold text-gray-900 leading-tight tracking-tight";
      case "h2":
        return "text-3xl font-bold text-gray-900 leading-tight tracking-tight";
      case "h3":
        return "text-2xl font-semibold text-gray-900 leading-tight";
      case "h4":
        return "text-xl font-semibold text-gray-900 leading-tight";
      case "h5":
        return "text-lg font-medium text-gray-900 leading-tight";
      case "h6":
        return "text-base font-medium text-gray-900 leading-tight";
      case "p":
        return "text-base text-gray-700 leading-relaxed";
      case "span":
        return "text-base text-gray-700";
      case "strong":
        return "font-bold text-gray-900";
      case "em":
        return "italic text-gray-800";
      case "small":
        return "text-sm text-gray-600";
      case "mark":
        return "bg-yellow-200 text-gray-900 px-1 rounded";
      case "code":
        return "bg-gray-100 text-gray-800 px-2 py-1 rounded text-sm font-mono";
      case "pre":
        return "bg-gray-100 text-gray-800 p-4 rounded-lg text-sm font-mono overflow-x-auto";
      case "blockquote":
        return "border-l-4 border-blue-500 pl-4 italic text-gray-700 text-lg";
      case "time":
        return "text-sm text-gray-600 font-mono";
      case "u":
        return "underline text-gray-800";
      case "i":
        return "italic text-gray-800";
      case "b":
        return "font-bold text-gray-900";
      case "s":
        return "line-through text-gray-600";
      case "sub":
        return "text-sm text-gray-600 align-sub";
      case "sup":
        return "text-sm text-gray-600 align-super";
      case "q":
        return "italic text-gray-700";
      case "cite":
        return "italic text-gray-600 text-sm";
      case "abbr":
        return "border-b border-dotted border-gray-400 cursor-help";
      case "del":
        return "line-through text-gray-500";
      case "ins":
        return "underline text-green-700 bg-green-50 px-1 rounded";
      default:
        return "text-gray-900";
    }
  };

  const Component = tag as React.ElementType;
  const classNames = getTagClasses(tag);

  return (
    <Component id={id} className={classNames} {...props}>
      {children}
    </Component>
  );
};

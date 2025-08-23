import React from "react";
import { Icon } from "@iconify/react";
import { FieldConfig } from "../interfaces/Field";

export const Field: React.FC<FieldConfig> = ({
  tag = "input",
  type = "text",
  role = "default",
  size = "md",
  placeholder,
  value,
  checked,
  icon,
  children,
  onChange,
}) => {
  const Tag = tag;
  const isCheckboxOrRadio = type === "checkbox" || type === "radio";
  const defaultClasses =
    "border-2 outline-none transition-colors duration-200 w-full";
  const roleClasses = {
    "default": "border-gray-300 focus:border-blue-500 focus:ring-blue-500",
    "error": "border-red-500 focus:border-red-600 focus:ring-red-500",
    "success": "border-green-500 focus:border-green-600 focus:ring-green-500",
  };
  const sizeClasses = {
    "sm": "px-2 py-1 text-sm rounded-md",
    "md": "px-3 py-2 text-base rounded-md",
    "lg": "px-4 py-2 text-lg rounded-md",
  };
  const className = `${defaultClasses} ${roleClasses[role]} ${sizeClasses[size]}`;

  if (isCheckboxOrRadio) {
    return (
      <label className={className}>
        <input
          type={type}
          checked={checked}
          onChange={onChange as React.ChangeEventHandler<HTMLInputElement>}
          className={className}
        />
        {children}
      </label>
    );
  }

  return (
    <label className={className}>
      <Icon icon={`material-symbols-light:${icon}`} className={className} />
      <Tag
        type={type}
        placeholder={placeholder}
        value={value}
        onChange={onChange as any}
        className={className}
      />
      {children}
    </label>
  );
};

import React from "react";
import { Icon } from "@iconify/react";

export interface FieldInterface {
  label: string;
  icon?: string;
  type?: string;
  name: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => void;
  placeholder?: string;
  required?: boolean;
  className?: string;
  min?: string | number;
  max?: string | number;
  step?: string | number;
  readOnly?: boolean;
  children?: React.ReactNode;
}

export type FieldArrayInterface = FieldInterface[];

const Field: React.FC<FieldInterface> = ({
  label,
  icon,
  type = "text",
  name,
  value,
  onChange,
  placeholder,
  required = false,
  className = "",
  min,
  max,
  step,
  readOnly = false,
  children,
}) => {
  const baseInputClasses = "mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500";
  const readOnlyClasses = readOnly ? "bg-gray-100 cursor-not-allowed" : "";
  
  const renderInput = () => {
    switch (type) {
      case "textarea":
        return (
          <textarea
            name={name}
            value={value}
            onChange={onChange}
            placeholder={placeholder}
            required={required}
            readOnly={readOnly}
            className={`${baseInputClasses} ${readOnlyClasses} resize-vertical min-h-[80px]`}
          />
        );
      case "select":
        return (
          <select
            name={name}
            value={value}
            onChange={onChange}
            required={required}
            disabled={readOnly}
            className={`${baseInputClasses} ${readOnlyClasses}`}
          >
            {children}
          </select>
        );
      default:
        return (
          <input
            type={type}
            name={name}
            value={value}
            onChange={onChange}
            placeholder={placeholder}
            required={required}
            min={min}
            max={max}
            step={step}
            readOnly={readOnly}
            className={`${baseInputClasses} ${readOnlyClasses}`}
          />
        );
    }
  };

  return (
    <div className={className}>
      {icon && <Icon icon={icon} />}
      <label htmlFor={name} className="block text-sm font-medium text-gray-700">
        {label}
      </label>
      {renderInput()}
    </div>
  );
};

export default Field;

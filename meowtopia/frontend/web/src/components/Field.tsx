import React from "react";
import { Icon } from "@iconify/react";

export interface FieldInterface {
  label: string;
  icon?: string;
  type?: string;
  name: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  placeholder?: string;
  required?: boolean;
  className?: string;
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
}) => (
  <label className={className}>
    {icon && <Icon icon={icon} />}
    <p>{label}</p>
    <input
      type={type}
      name={name}
      value={value}
      onChange={onChange}
      placeholder={placeholder}
      required={required}
    />
  </label>
);

export default Field;

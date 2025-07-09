import React from "react";
import { Icon } from "@iconify/react";
import { FieldInterface } from "@/types/interfaces/FieldInterface";

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

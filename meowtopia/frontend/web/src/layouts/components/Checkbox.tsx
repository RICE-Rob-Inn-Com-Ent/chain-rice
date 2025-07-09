import React from "react";
import { CheckboxInterface } from "@/types/interfaces/CheckboxInterface";

const Checkbox: React.FC<CheckboxInterface> = ({
  label,
  checked,
  onChange,
  required = false,
  className = "",
}) => (
  <label className={className}>
    <input
      type="checkbox"
      checked={checked}
      onChange={onChange}
      required={required}
    />
    {label}
  </label>
);

export default Checkbox;

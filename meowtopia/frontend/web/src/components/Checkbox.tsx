import React from "react";

export interface CheckboxInterface {
  label: React.ReactNode;
  checked: boolean;
  onChange: () => void;
  required?: boolean;
  className?: string;
}

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

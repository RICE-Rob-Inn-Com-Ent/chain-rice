import React, { useState } from "react";
import { Icon } from "@iconify/react";

interface PasswordFieldProps {
  label: string;
  icon?: string;
  name: string;
  placeholder?: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  required?: boolean;
  className?: string;
}

const PasswordField: React.FC<PasswordFieldProps> = ({
  label,
  icon,
  name,
  placeholder,
  value,
  onChange,
  required = false,
  className = "",
}) => {
  const [show, setShow] = useState(false);
  return (
    <label className={className}>
      {icon && <Icon icon={icon} />}
      <p>{label}</p>
      <input
        type={show ? "text" : "password"}
        name={name}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        required={required}
      />
      <button
        type="button"
        onClick={() => setShow((s) => !s)}
        style={{ marginLeft: 8 }}
        tabIndex={-1}
      >
        <Icon icon={show ? "mdi:eye-off" : "mdi:eye"} />
      </button>
    </label>
  );
};

export default PasswordField; 
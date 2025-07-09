import React from "react";
import { Icon } from "@iconify/react";
import { ButtonInterface } from "@/types/interfaces/ButtonInterface";

const Button: React.FC<ButtonInterface> = ({
  type = "button",
  loading = false,
  icon,
  children,
  onClick,
  className = "",
  disabled = false,
}) => (
  <button
    type={type}
    onClick={onClick}
    className={className}
    disabled={disabled || loading}
  >
    {loading && <Icon icon="line-md:loading-alt-loop" />} {children}
    {icon && <Icon icon={icon} />}
  </button>
);

export default Button;

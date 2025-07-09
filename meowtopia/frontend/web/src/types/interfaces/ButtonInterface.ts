export interface ButtonInterface {
  type?: "button" | "submit";
  loading?: boolean;
  icon?: string;
  children: React.ReactNode;
  onClick?: () => void;
  className?: string;
  disabled?: boolean;
}

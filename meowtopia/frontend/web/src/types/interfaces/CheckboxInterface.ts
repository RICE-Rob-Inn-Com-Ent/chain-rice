export interface CheckboxInterface {
  label: React.ReactNode;
  checked: boolean;
  onChange: () => void;
  required?: boolean;
  className?: string;
}

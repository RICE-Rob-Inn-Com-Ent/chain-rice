// ============================================================================
// GLOBAL INTERFACES (App-wide, not just Auth)
// ============================================================================

export interface FieldConfig {
  label: string;
  placeholder: string;
  icon: string;
  type: 'text' | 'email' | 'password' | 'tel' | 'url';
  required: boolean;
  validation?: {
    pattern?: string;
    minLength?: number;
    maxLength?: number;
    custom?: (value: string) => string | null;
  };
}

export interface ButtonConfig {
  text: string;
  icon?: string;
  variant: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
  size: 'sm' | 'md' | 'lg';
  loading?: boolean;
  disabled?: boolean;
} 
export interface CommonMessages {
  loading: string;
  error: string;
  success: string;
  cancel: string;
  save: string;
  delete: string;
  edit: string;
  view: string;
  back: string;
  next: string;
  previous: string;
  submit: string;
  reset: string;
  close: string;
  confirm: string;
  yes: string;
  no: string;
}
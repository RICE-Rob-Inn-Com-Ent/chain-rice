import React from 'react'
import clsx from 'clsx'

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'outline'
  size?: 'sm' | 'md' | 'lg'
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', ...props }, ref) => {
    const base = 'inline-flex items-center justify-center rounded-md font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed'
    const sizes = {
      sm: 'h-8 px-3 text-xs',
      md: 'h-10 px-4 text-sm',
      lg: 'h-11 px-5 text-base',
    }[size]
    const variants = {
      primary: 'bg-brand-500 text-slate-900 hover:bg-brand-400',
      outline: 'border border-white/20 bg-transparent text-slate-200 hover:bg-white/10',
    }[variant]
    return (
      <button ref={ref} className={clsx(base, sizes, variants, className)} {...props} />
    )
  }
)
Button.displayName = 'Button'

export default Button

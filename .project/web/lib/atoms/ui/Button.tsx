import React from 'react'
import clsx from 'clsx'

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'outline' | 'gradient'
  size?: 'sm' | 'md' | 'lg'
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', ...props }, ref) => {
    const base = 'inline-flex items-center justify-center rounded-md font-medium transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2'
    const sizes = {
      sm: 'h-8 px-3 text-xs',
      md: 'h-10 px-4 text-sm',
      lg: 'h-11 px-5 text-base',
    }[size]
    const variants = {
      primary: 'bg-cyan-500 text-slate-900 hover:bg-cyan-400 focus-visible:outline-cyan-300',
      outline: 'border border-white/20 bg-transparent text-slate-200 hover:bg-white/10 focus-visible:outline-white/40',
      gradient: 'bg-gradient-to-r from-cyan-400 to-emerald-400 text-slate-900 hover:from-cyan-300 hover:to-emerald-300 shadow-[0_0_0_0_rgba(0,0,0,0)] hover:shadow-[0_0_24px_rgba(16,185,129,0.35),0_0_48px_rgba(34,211,238,0.25)] focus-visible:outline-cyan-300'
    }[variant]
    return (
      <button ref={ref} className={clsx(base, sizes, variants, className)} {...props} />
    )
  }
)
Button.displayName = 'Button'

export default Button

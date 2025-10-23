import React from 'react'
import clsx from 'clsx'

type TextareaProps = React.TextareaHTMLAttributes<HTMLTextAreaElement> & {
  label?: string
}

export const Textarea = React.forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ label, className, id, ...props }, ref) => {
    const inputId = id || props.name || Math.random().toString(36).slice(2)
    return (
      <div className="grid gap-1.5">
        {label && (
          <label htmlFor={inputId} className="text-sm text-slate-300">
            {label}
          </label>
        )}
        <textarea
          id={inputId}
          ref={ref}
          className={clsx(
            'rounded-md border border-white/10 bg-white/5 px-3 py-2 text-slate-100 placeholder:text-slate-400 outline-none focus:border-brand-400 focus:ring-1 focus:ring-brand-400',
            className
          )}
          {...props}
        />
      </div>
    )
  }
)
Textarea.displayName = 'Textarea'

export default Textarea

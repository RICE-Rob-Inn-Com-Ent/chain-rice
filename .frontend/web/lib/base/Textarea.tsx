import React from 'react';
import clsx from 'clsx';

type TextareaProps = React.TextareaHTMLAttributes<HTMLTextAreaElement> & {
  label?: string;
  floating?: boolean;
  neutralFocus?: boolean;
};

export const Textarea = React.forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ label, className, id, floating = false, placeholder, neutralFocus = false, ...props }, ref) => {
    const inputId = id || props.name || Math.random().toString(36).slice(2);

    if (floating) {
      return (
        <div className="relative group">
          {/* Halo gradient tylko gdy nie neutralny focus */}
          {!neutralFocus && (
            <div className="pointer-events-none absolute -inset-px rounded-md bg-gradient-to-r from-cyan-400/30 via-teal-300/30 to-emerald-400/30 opacity-0 blur-[8px] transition-opacity duration-200 group-focus-within:opacity-100" />
          )}
          <textarea
            id={inputId}
            ref={ref}
            placeholder={typeof placeholder === 'string' ? ' ' : ' '}
            className={clsx(
              'peer w-full rounded-md border border-white/15 bg-white/5 px-3 py-3 text-slate-100 placeholder-transparent outline-none transition-colors duration-200',
              neutralFocus
                ? 'focus:border-white/30 focus:ring-0'
                : 'focus:border-cyan-300 focus:ring-2 focus:ring-cyan-300/50',
              className
            )}
            {...props}
          />
          {label && (
            <label
              htmlFor={inputId}
              className={clsx(
                'pointer-events-none absolute left-3 top-3 text-[13px] text-slate-400 transition-all duration-200 ease-out',
                neutralFocus
                  ? 'peer-focus:top-1.5 peer-focus:text-xs peer-focus:text-slate-200'
                  : 'peer-focus:top-1.5 peer-focus:text-xs peer-focus:text-cyan-100',
                'peer-[&:not(:placeholder-shown)]:top-1.5 peer-[&:not(:placeholder-shown)]:text-xs peer-[&:not(:placeholder-shown)]:text-slate-300'
              )}
            >
              {label}
            </label>
          )}
        </div>
      );
    }

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
            'rounded-md border border-white/10 bg-white/5 px-3 py-2 text-slate-100 placeholder:text-slate-400 outline-none',
            neutralFocus
              ? 'focus:border-white/30 focus:ring-0'
              : 'focus:border-cyan-300 focus:ring-2 focus:ring-cyan-300/50',
            className
          )}
          placeholder={placeholder}
          {...props}
        />
      </div>
    );
  }
);
Textarea.displayName = 'Textarea';

export default Textarea;

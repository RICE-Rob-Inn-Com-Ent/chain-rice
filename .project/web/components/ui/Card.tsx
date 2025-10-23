import React from 'react'
import clsx from 'clsx'

type CardProps = React.HTMLAttributes<HTMLDivElement> & {
  title?: string
}

export const Card: React.FC<CardProps> = ({ title, className, children, ...rest }) => {
  return (
    <div className={clsx('rounded-xl border border-white/10 bg-white/5 p-5', className)} {...rest}>
      {title && <h3 className="mb-2 text-lg font-semibold text-white">{title}</h3>}
      {children}
    </div>
  )
}

export default Card

import React from 'react'

interface SectionProps {
  id?: string
  className?: string
  children?: React.ReactNode
}

const Section: React.FC<SectionProps> = ({ id, className = '', children }) => {
  return (
    <section id={id} className={`mx-auto max-w-7xl px-4 py-16 md:py-24 ${className}`}>
      {children}
    </section>
  )
}

export default Section

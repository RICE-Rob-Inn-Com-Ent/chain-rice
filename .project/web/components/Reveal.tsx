"use client";
import React, { useEffect, useRef, useState } from 'react'

type RevealProps = {
  as?: keyof JSX.IntrinsicElements
  className?: string
  children?: React.ReactNode
  threshold?: number
}

export default function Reveal({ as = 'div', className = '', children, threshold = 0.15 }: RevealProps) {
  const Comp: any = as
  const ref = useRef<HTMLElement | null>(null)
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    const node = ref.current
    if (!node) return
    const obs = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) {
            setVisible(true)
            obs.disconnect()
          }
        })
      },
      { threshold }
    )
    obs.observe(node)
    return () => obs.disconnect()
  }, [threshold])

  return (
    <Comp ref={ref} className={`fade-in ${visible ? 'visible' : ''} ${className}`}>
      {children}
    </Comp>
  )
}

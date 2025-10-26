"use client";
import React, { useEffect, useRef, useState } from "react";

type RevealProps = {
  as?: keyof JSX.IntrinsicElements;
  className?: string;
  children?: React.ReactNode;
  threshold?: number;
  /** Zachowaj wsteczną kompatybilność: stary props w sekundach (mnożony ×100 dla zgodności) */
  delay?: number;
  /** Nazwa klasy efektu (np. 'fade-in', 'fade-down-slow') */
  effectClass?: string;
  /** Opcjonalne opóźnienie animacji w ms */
  delayMs?: number;
};

export default function Reveal({
  as = "div",
  className = "",
  children,
  threshold = 0.15,
  effectClass = "fade-in",
  delay,
  delayMs,
}: RevealProps) {
  const Comp: any = as;
  const ref = useRef<HTMLElement | null>(null);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const node = ref.current;
    if (!node) return;
    const obs = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) {
            setVisible(true);
            obs.disconnect();
          }
        });
      },
      { threshold }
    );
    obs.observe(node);
    return () => obs.disconnect();
  }, [threshold]);

  const wrapperClass = `${effectClass} ${visible ? "visible" : ""} ${className}`;
  // zachowaj kompatybilność: jeśli delayMs nie podano, przelicz delay w sekundach na ~ms zgodnie z wcześniejszym zachowaniem (×100)
  const resolvedDelayMs = delayMs ?? (typeof delay === "number" ? delay * 100 : undefined);
  const style = resolvedDelayMs && visible ? { transitionDelay: `${resolvedDelayMs}ms` } : undefined;

  return (
    <Comp ref={ref} className={wrapperClass} style={style}>
      {children}
    </Comp>
  );
}

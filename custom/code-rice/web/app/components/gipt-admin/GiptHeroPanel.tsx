import type { ReactNode } from "react";
import clsx from "clsx";

type GiptHeroPanelProps = {
  icon: ReactNode;
  title: string;
  subtitle: string;
  accent?: string;
};

export function GiptHeroPanel({
  icon,
  title,
  subtitle,
  accent = "border-purple-500/50 text-purple-400",
}: GiptHeroPanelProps) {
  return (
    <section className="flex min-h-screen flex-1 items-center justify-center px-8 py-20">
      <div className="relative w-full max-w-4xl text-center">
        {/* Animated background orbs */}
        <div className="absolute inset-0 -z-10 overflow-hidden">
          <div className="absolute -left-32 -top-32 h-96 w-96 rounded-full bg-purple-500/20 blur-[120px] animate-pulse" />
          <div className="absolute -right-32 -bottom-32 h-96 w-96 rounded-full bg-pink-500/20 blur-[120px] animate-pulse" style={{ animationDelay: '1s' }} />
          <div className="absolute left-1/2 top-1/2 h-64 w-64 -translate-x-1/2 -translate-y-1/2 rounded-full bg-indigo-500/10 blur-[100px] animate-pulse" style={{ animationDelay: '2s' }} />
        </div>

        {/* Icon container with modern glassmorphism */}
        <div className="relative mx-auto mb-10 inline-block">
          {/* Outer glow ring */}
          <div className="absolute inset-0 -m-4 rounded-3xl bg-gradient-to-br from-purple-500/30 via-pink-500/20 to-indigo-500/30 blur-2xl opacity-60 animate-pulse" />
          
          {/* Icon container */}
          <div
            className={clsx(
              "relative flex h-32 w-32 items-center justify-center rounded-3xl border border-white/10",
              "bg-gradient-to-br from-white/5 via-white/[0.02] to-transparent",
              "backdrop-blur-xl shadow-[0_8px_32px_rgba(0,0,0,0.4),inset_0_1px_0_rgba(255,255,255,0.1)]",
              "transition-all duration-500 hover:scale-105 hover:shadow-[0_12px_48px_rgba(139,92,246,0.4)]",
              accent,
            )}
          >
            {/* Inner glow */}
            <div className="absolute inset-0 rounded-3xl bg-gradient-to-br from-purple-500/20 to-transparent opacity-0 transition-opacity duration-500 hover:opacity-100" />
            
            {/* Icon */}
            <div className="relative z-10 text-6xl drop-shadow-[0_4px_12px_rgba(139,92,246,0.5)]">
              {icon}
            </div>
          </div>
        </div>
        
        {/* Title with modern gradient */}
        <h1 className="mb-6 text-6xl font-bold tracking-tight">
          <span className="bg-gradient-to-r from-white via-purple-100 to-pink-200 bg-clip-text text-transparent drop-shadow-[0_2px_8px_rgba(139,92,246,0.3)]">
            {title}
          </span>
        </h1>
        
        {/* Subtitle */}
        <p className="mx-auto max-w-2xl text-xl font-medium text-gray-300/90 leading-relaxed">
          {subtitle}
        </p>
      </div>
    </section>
  );
}


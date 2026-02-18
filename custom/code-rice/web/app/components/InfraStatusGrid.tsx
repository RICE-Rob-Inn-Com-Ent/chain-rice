import { Icon } from "@iconify/react";

const SERVICES: { name: string; status: "online" | "degraded" | "offline"; description: string; icon?: string }[] = [
  {
    name: "Postgres / code-rice",
    status: "online",
    description: "Replica set + PITR snapshot co 15 minut",
    icon: "mdi:database",
  },
  {
    name: "MongoDB vector store",
    status: "online",
    description: "Cluster devcontainer-mongodb:27017",
    icon: "mdi:database-network",
  },
  {
    name: "Redis events",
    status: "online",
    description: "Pub/Sub dla kolejek LoRA",
    icon: "mdi:database-sync",
  },
  {
    name: "Vault secrets",
    status: "degraded",
    description: "Rolling restart - unseal trwa 3 min",
    icon: "mdi:lock",
  },
  {
    name: "Grafana / Loki",
    status: "online",
    description: "Telemetry stack 24/7",
    icon: "mdi:chart-line",
  },
  {
    name: "Jaeger OTLP",
    status: "online",
    description: "Tracing dla treningów",
    icon: "mdi:graph",
  },
];

const STATUS_STYLES: Record<string, { badge: string; dot: string; glow: string }> = {
  online: {
    badge: "text-emerald-400 bg-emerald-400/10 border-emerald-400/40",
    dot: "bg-emerald-400",
    glow: "shadow-[0_0_20px_rgba(16,185,129,0.3)]",
  },
  degraded: {
    badge: "text-amber-300 bg-amber-400/10 border-amber-400/40",
    dot: "bg-amber-400",
    glow: "shadow-[0_0_20px_rgba(251,191,36,0.3)]",
  },
  offline: {
    badge: "text-red-400 bg-red-400/10 border-red-400/40",
    dot: "bg-red-400",
    glow: "shadow-[0_0_20px_rgba(248,113,113,0.3)]",
  },
};

export function InfraStatusGrid() {
  return (
    <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
      {SERVICES.map((service, idx) => {
        const statusStyle = STATUS_STYLES[service.status];
        return (
          <article
            key={service.name}
            className="group relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-void-900/80 to-void-800/60 p-6 backdrop-blur-sm transition-all duration-500 hover:scale-[1.02] hover:border-white/20 hover:shadow-lg"
            style={{ animationDelay: `${idx * 0.1}s` }}
          >
            <div className="absolute inset-0 bg-gradient-to-br from-ion-500/5 to-purple-500/5 opacity-0 transition-opacity duration-500 group-hover:opacity-100" />
            <div className="relative z-10">
              <div className="mb-4 flex items-center justify-between gap-3">
                <div className="flex items-center gap-3">
                  {service.icon && (
                    <div className="rounded-lg bg-gradient-to-br from-void-800/50 to-void-900/50 p-2.5 backdrop-blur-sm transition-transform group-hover:scale-110">
                      <Icon icon={service.icon} className="h-5 w-5 text-ion-300" />
                    </div>
                  )}
                  <h3 className="text-lg font-semibold text-white">{service.name}</h3>
                </div>
                <div className="flex items-center gap-2">
                  {service.status === "online" && (
                    <span className="relative flex h-2 w-2">
                      <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75"></span>
                      <span className="relative inline-flex h-2 w-2 rounded-full bg-emerald-400"></span>
                    </span>
                  )}
                  <span
                    className={`rounded-full border px-3 py-1 text-xs font-semibold uppercase tracking-wide transition-all ${statusStyle.badge} ${statusStyle.glow}`}
                  >
                    {service.status === "online" ? "ONLINE" : service.status === "degraded" ? "DEGRADED" : "OFFLINE"}
                  </span>
                </div>
              </div>
              <p className="text-sm leading-relaxed text-white/70">{service.description}</p>
            </div>
          </article>
        );
      })}
    </div>
  );
}



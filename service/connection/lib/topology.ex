defmodule Service.Cluster.Topology do
  @moduledoc """
  Libcluster topology wiring: named strategies, polling intervals, and optional `Cluster.Supervisor` child.

  Reads `config :service, Service.Cluster` — see `config/config.exs`. Use `Service.Cluster.Strategy`
  helpers to build each topology entry.

  When clustering is enabled, `Service.Guard.Supervisor` includes these via `Service.Cluster.Topology.children/0`
  (see `service/guard/supervisor.ex`).
  """

  # TODO:
  # [ ] implement libcluster topology config:
  #     strategy from RICE_CLUSTER_STRATEGY env var:
  #     Cluster.Strategy.Kubernetes — prod
  #     Cluster.Strategy.Gossip — dev/local
  #     Cluster.Strategy.DNSPoll — docker-compose
  # [ ] implement Kubernetes strategy config:
  #     kubernetes_selector from RICE_CLUSTER_K8S_SELECTOR env var
  #     kubernetes_namespace from RICE_CLUSTER_K8S_NAMESPACE env var

  @spec topologies() :: keyword()
  def topologies do
    Application.get_env(:service, Service.Cluster, [])
    |> Keyword.get(:topologies, [])
  end

  @spec enabled?() :: boolean()
  def enabled? do
    Application.get_env(:service, Service.Cluster, [])
    |> Keyword.get(:enabled, false)
  end

  @doc """
  When `enabled?/0` is true, children include LibCluster, Horde registry,
  Horde distributed supervisor, cluster observer.
  """
  @spec children() :: [Supervisor.child_spec() | {module(), term()}]
  def children do
    if enabled?() do
      [
        {Cluster.Supervisor, [topologies(), [name: Service.Cluster.LibClusterSupervisor]]},
        Service.Cluster.Registry.child_spec([]),
        Service.Cluster.Supervisor.child_spec([]),
        Service.Cluster.Observer.child_spec([])
      ]
    else
      []
    end
  end
end

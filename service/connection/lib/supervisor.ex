defmodule Service.Cluster.Supervisor do
  @moduledoc """
  Horde `Horde.DynamicSupervisor` — one cluster-wide supervisor for dynamic workers (distribution strategy, members).

  Name and strategy default from `config :service, Service.Cluster, :horde`. Use `Horde.DynamicSupervisor.start_child/2`
  with `Service.Cluster.Supervisor.name/0` as the supervisor reference.
  """

  # TODO:
  # [ ] implement Horde.DynamicSupervisor:
  #     distributes children across cluster nodes
  #     on node failure → children migrate to healthy nodes
  # [ ] implement child migration policy:
  #     RICE_CLUSTER_MIGRATION=true activates auto-migration
  #     migration timeout from RICE_CLUSTER_MIGRATION_TIMEOUT_S

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts \\ []) do
    cfg = horde_cfg()

    defaults = [
      name: Keyword.get(opts, :dynamic_supervisor_name, cfg[:dynamic_supervisor_name]),
      strategy: :one_for_one,
      members: :auto,
      distribution_strategy: Keyword.get(opts, :distribution_strategy, cfg[:distribution_strategy])
    ]

    Horde.DynamicSupervisor.child_spec(Keyword.merge(defaults, opts))
  end

  @spec name() :: atom()
  def name do
    horde_cfg()[:dynamic_supervisor_name] ||
      raise "missing :horde :dynamic_supervisor_name in Service.Cluster config"
  end

  defp horde_cfg do
    Application.get_env(:service, Service.Cluster, [])
    |> Keyword.get(:horde, [])
  end
end

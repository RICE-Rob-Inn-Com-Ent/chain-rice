defmodule Smith.Connection.Supervisor do
  @moduledoc """
  **`Horde.DynamicSupervisor`** for dynamic SMITH workers in the cluster.

  Distribution strategy is set in `config :service, Smith.Connection, horde: [distribution_strategy: …]`
  (e.g. `Smith.Connection.Strategy.LeastRunQueue` or `Smith.Connection.Strategy.RoundRobinHorde`).

  After node membership changes, call `Smith.Connection.Handoff.sync_horde_members!/0` (Observer does this on boot).
  """

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts \\ []) do
    cfg = horde_cfg()

    defaults = [
      name: Keyword.get(opts, :dynamic_supervisor_name, cfg[:dynamic_supervisor_name]),
      strategy: :one_for_one,
      members: :auto,
      distribution_strategy:
        Keyword.get(opts, :distribution_strategy, cfg[:distribution_strategy] || Horde.UniformDistribution)
    ]

    Horde.DynamicSupervisor.child_spec(Keyword.merge(defaults, opts))
  end

  @spec name() :: atom()
  def name do
    horde_cfg()[:dynamic_supervisor_name] ||
      raise ArgumentError, "missing :horde :dynamic_supervisor_name in :service, Smith.Connection config"
  end

  defp horde_cfg do
    Application.get_env(:service, Smith.Connection, [])
    |> Keyword.get(:horde, [])
  end
end

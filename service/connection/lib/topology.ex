defmodule Smith.Connection.Topology do
  @moduledoc """
  **libcluster**: Gossip / DNS-poll / Epmd / Kubernetes strategies (see `Smith.Connection.Strategy`).

  Enable with `config :service, Smith.Connection, enabled: true` and `topologies: [...]`.

  `Smith.Guard.Supervisor` wires children via `children/0` (see `service/guard/lib/supervisor.ex`).

  For Guard / monitoring: `nodes_status/0`, `visible_nodes/0`, `local_node_stats/0` (the last is handy for `:rpc`).
  """

  @spec conn_cfg() :: keyword()
  def conn_cfg do
    Application.get_env(:service, Smith.Connection, []) |> List.wrap()
  end

  @spec topologies() :: keyword()
  def topologies do
    Keyword.get(conn_cfg(), :topologies, [])
  end

  @spec enabled?() :: boolean()
  def enabled? do
    Keyword.get(conn_cfg(), :enabled, false)
  end

  @doc "Active discovery strategy (`:gossip`, `:dns`, `:epmd`, `:kubernetes_dns`, …) — from config."
  @spec discovery_mode() :: atom()
  def discovery_mode do
    Keyword.get(conn_cfg(), :discovery, :epmd)
  end

  @doc "Erlang nodes visible to this node (`Node.self/0` + `Node.list/0`)."
  @spec visible_nodes() :: [node()]
  def visible_nodes do
    [Node.self() | Node.list()] |> Enum.uniq()
  end

  @doc """
  Cluster status summary for Guard integration: local metrics + `:rpc` to peer nodes.

  Returns `%{nodes: [...], self: node(), visible_count: integer()}`.
  """
  @spec nodes_status() :: map()
  def nodes_status do
    self = Node.self()
    peers = Node.list()

    nodes =
      [self | peers]
      |> Enum.uniq()
      |> Enum.map(fn n ->
        stats =
          if n == self do
            local_node_stats()
          else
            case :rpc.call(n, __MODULE__, :local_node_stats, [], 2_000) do
              {:badrpc, reason} -> %{error: :badrpc, reason: inspect(reason)}
              other -> other
            end
          end

        %{node: n, stats: stats}
      end)

    %{
      self: self,
      visible_count: length(nodes),
      nodes: nodes,
      libcluster?: enabled?()
    }
  end

  @doc "Metrics for the current node (BEAM) — called locally and via `:rpc`."
  @spec local_node_stats() :: map()
  def local_node_stats do
    mem = :erlang.memory()

    %{
      run_queue: :erlang.statistics(:run_queue),
      schedulers_online: :erlang.system_info(:schedulers_online),
      memory_total_bytes: Keyword.get(mem, :total, 0),
      memory_processes_bytes: Keyword.get(mem, :processes, 0),
      uptime_ms: :erlang.system_info(:uptime) * 1000
    }
  end

  @doc """
  Children to embed under Guard: LibCluster, Horde.Registry, Horde.DynamicSupervisor, Observer.

  After LibCluster starts, `Smith.Connection.Handoff.sync_horde_members!/0` reconciles Horde members.
  """
  @spec children() :: [Supervisor.child_spec() | {module(), term()}]
  def children do
    if enabled?() do
      [
        {Cluster.Supervisor, [topologies(), [name: Smith.Connection.LibClusterSupervisor]]},
        Smith.Connection.Registry.child_spec([]),
        Smith.Connection.Supervisor.child_spec([]),
        Smith.Connection.Observer.child_spec(name: Smith.Connection.Observer)
      ]
    else
      []
    end
  end
end

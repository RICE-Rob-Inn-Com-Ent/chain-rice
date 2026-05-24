defmodule Smith.Connection.Strategy do
  @moduledoc """
  Two layers:

  1. **libcluster** — DSL for `topologies` (Gossip, DNS-poll, Epmd, Kubernetes).
  2. **Cluster placement** — `pick_node/2` for manual node choice (`:round_robin`, `:least_loaded`)
     and **`Horde.DistributionStrategy`** modules for `Horde.DynamicSupervisor` (KING / maximum performance).
  """

  @typedoc "Specification for a single libcluster topology."
  @type topology_spec :: keyword()

  # --- libcluster builders (return keyword for Cluster.Supervisor) ---

  @spec gossip(keyword()) :: topology_spec()
  def gossip(opts \\ []) do
    [strategy: Cluster.Strategy.Gossip, config: opts]
  end

  @spec dns_poll(keyword()) :: topology_spec()
  def dns_poll(opts \\ []) do
    [
      strategy: Cluster.Strategy.DNSPoll,
      config:
        Keyword.merge(
          [
            polling_interval: 5_000
          ],
          opts
        )
    ]
  end

  @spec kubernetes_dns(keyword()) :: topology_spec()
  def kubernetes_dns(opts \\ []) do
    [
      strategy: Cluster.Strategy.Kubernetes.DNS,
      config:
        Keyword.merge(
          [
            polling_interval: 5_000
          ],
          opts
        )
    ]
  end

  @spec kubernetes_api(keyword()) :: topology_spec()
  def kubernetes_api(opts \\ []) do
    [
      strategy: Cluster.Strategy.Kubernetes,
      config:
        Keyword.merge(
          [
            polling_interval: 5_000
          ],
          opts
        )
    ]
  end

  @spec epmd(keyword()) :: topology_spec()
  def epmd(opts \\ []) do
    [strategy: Cluster.Strategy.Epmd, config: opts]
  end

  # --- placement helpers (Pipeline / Guard without pinning to a physical node) ---

  @doc """
  Chooses a node from `nodes` by mode:

  * `:round_robin` — global counter (`:persistent_term`);
  * `:least_loaded` — minimum `:erlang.statistics(:run_queue)` (via `:rpc` on remote nodes).
  """
  @spec pick_node([node()], :round_robin | :least_loaded) :: node()
  def pick_node(nodes, mode \\ :round_robin)
  def pick_node([], _), do: Node.self()

  def pick_node(nodes, :round_robin) when is_list(nodes) do
    nodes = Enum.uniq(nodes)
    key = :smith_connection_rr
    i = (:persistent_term.get(key) rescue 0)
    _ = :persistent_term.put(key, i + 1)
    Enum.at(nodes, rem(i, length(nodes)))
  end

  def pick_node(nodes, :least_loaded) when is_list(nodes) do
    nodes = Enum.uniq(nodes)

    Enum.min_by(nodes, &remote_run_queue/1, fn -> hd(nodes) end)
  end

  defp remote_run_queue(n) when n == node(), do: :erlang.statistics(:run_queue)

  defp remote_run_queue(n) do
    case :rpc.call(n, :erlang, :statistics, [:run_queue], 1_500) do
      q when is_integer(q) -> q
      _ -> 1_000_000
    end
  end

  @doc "Run-queue estimate for a Horde member (see `LeastRunQueue` below)."
  @spec member_run_queue_estimate(term()) :: non_neg_integer()
  def member_run_queue_estimate(member) do
    n = member_node(member)

    if n == node() do
      :erlang.statistics(:run_queue)
    else
      case :rpc.call(n, :erlang, :statistics, [:run_queue], 800) do
        q when is_integer(q) -> q
        _ -> 999_999
      end
    end
  end

  defp member_node(%{name: {_a, n}}) when is_atom(n), do: n
  defp member_node(%{name: name}) when is_tuple(name) and tuple_size(name) >= 2, do: elem(name, 1)
  defp member_node(%{name: _}), do: node()
  defp member_node(_), do: node()

  defmodule RoundRobinHorde do
    @moduledoc "Round-robin selection among Horde.DynamicSupervisor members."
    @behaviour Horde.DistributionStrategy

    @key :smith_connection_horde_rr

    @impl true
    def has_quorum?(members), do: members != []

    @impl true
    def choose_node(_spec, []), do: {:error, "no members"}

    def choose_node(_spec, members) do
      n = length(members)
      i = (:persistent_term.get(@key) rescue 0)
      _ = :persistent_term.put(@key, i + 1)
      {:ok, Enum.at(members, rem(i, n))}
    end
  end

  defmodule LeastRunQueue do
    @moduledoc "Pick a Horde member with the smallest scheduler run_queue on the node (KING / performance)."
    @behaviour Horde.DistributionStrategy

    @impl true
    def has_quorum?(members), do: members != []

    @impl true
    def choose_node(_spec, []), do: {:error, "no members"}

    def choose_node(_spec, members) do
      m =
        Enum.min_by(
          members,
          &Smith.Connection.Strategy.member_run_queue_estimate/1,
          fn -> hd(members) end
        )

      {:ok, m}
    end
  end
end

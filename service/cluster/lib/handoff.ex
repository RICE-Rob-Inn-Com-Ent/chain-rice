defmodule Service.Cluster.Handoff do
  @moduledoc """
  Node membership hooks and Horde member sync for process placement when nodes join or leave.

  Horde already restarts children on other nodes when `members: :auto` and a node stops; this module
  exposes optional MFAs and explicit `Horde.Cluster.set_members/2` when you manage membership manually.
  """

  # TODO:
  # [ ] implement process state handoff:
  #     on node shutdown → transfer state to another node
  #     uses Horde.Process.Handoff protocol
  # [ ] implement handoff timeout:
  #     RICE_CLUSTER_HANDOFF_TIMEOUT_S env var
  #     on timeout → new process starts with empty state

  require Logger

  @doc """
  Build `{name, node}` members for Horde from visible nodes (current node + `Node.list/0`).
  """
  @spec horde_members(atom()) :: [Horde.Cluster.member()]
  def horde_members(name) when is_atom(name) do
    ([Node.self()] ++ Node.list())
    |> Enum.uniq()
    |> Enum.map(fn n -> {name, n} end)
  end

  @doc """
  Push explicit Horde membership (skip when using `members: :auto` on registry/supervisor).
  """
  @spec set_members!(atom(), [Horde.Cluster.member()], timeout()) :: :ok | {:error, term()}
  def set_members!(horde, members, timeout \\ 5_000) do
    Horde.Cluster.set_members(horde, members, timeout)
  end

  @doc "Called from `Service.Cluster.Observer` on node up."
  @spec on_node_up(node()) :: :ok
  def on_node_up(node) do
    maybe_apply(Keyword.get(handoff_cfg(), :on_node_up_mfa), [node])
  end

  @doc "Called from `Service.Cluster.Observer` on node down."
  @spec on_node_down(node()) :: :ok
  def on_node_down(node) do
    maybe_apply(Keyword.get(handoff_cfg(), :on_node_down_mfa), [node])
  end

  defp handoff_cfg do
    Application.get_env(:service, Service.Cluster, [])
    |> Keyword.get(:handoff, [])
  end

  defp maybe_apply(nil, _), do: :ok

  defp maybe_apply({m, f, a}, extra) when is_atom(m) and is_atom(f) and is_list(a) do
    apply(m, f, a ++ extra)
    :ok
  rescue
    e ->
      Logger.error("Service.Cluster.Handoff MFA #{inspect({m, f, a})} failed: #{Exception.message(e)}")
      :ok
  end
end

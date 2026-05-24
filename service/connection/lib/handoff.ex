defmodule Smith.Connection.Handoff do
  @moduledoc """
  Reconciles **Horde** members after topology changes and stores snapshots for **auto-repair**.

  * `horde_members/1` — `{name, node}` tuples for `Horde.Cluster.set_members/3`.
  * `sync_horde_members!/0` — after libcluster, updates registry and dynamic supervisor (when enabled in config).
  * **ETS** `:smith_connection_handoff` — optional serialized state per key (e.g. a Horde process id)
    so a new node can recover data after `nodedown`.
  """

  require Logger

  @handoff_table :smith_connection_handoff

  @doc "ETS table for handoff snapshots (public; other nodes read via `:rpc`)."
  @spec handoff_table() :: atom()
  def handoff_table, do: @handoff_table

  @doc "Initialize ETS (idempotent)."
  @spec ensure_handoff_table!() :: :ok
  def ensure_handoff_table! do
    case :ets.whereis(@handoff_table) do
      :undefined ->
        _ = :ets.new(@handoff_table, [:named_table, :public, :set, read_concurrency: true])
        :ok

      _ ->
        :ok
    end
  end

  @doc "Store serialized state for a key (binary / term_to_binary)."
  @spec put_snapshot(term(), iodata()) :: :ok
  def put_snapshot(key, payload) when is_binary(payload) do
    ensure_handoff_table!()
    true = :ets.insert(@handoff_table, {key, payload})
    :ok
  end

  @doc "Read a snapshot; `:error` if missing."
  @spec take_snapshot(term()) :: {:ok, binary()} | :error
  def take_snapshot(key) do
    ensure_handoff_table!()

    case :ets.lookup(@handoff_table, key) do
      [{^key, bin}] ->
        :ets.delete(@handoff_table, key)
        {:ok, bin}

      [] ->
        :error
    end
  end

  @doc "List of `{horde_name, node}` for the currently visible cluster."
  @spec horde_members(atom()) :: [term()]
  def horde_members(name) when is_atom(name) do
    ([Node.self()] ++ Node.list())
    |> Enum.uniq()
    |> Enum.map(fn n -> {name, n} end)
  end

  @doc """
  Explicitly sync Horde Registry and Horde.DynamicSupervisor members after `nodeup` / boot.

  Set `sync_horde_members_on_boot: true` on `Smith.Connection` (default `true` when `enabled`).
  """
  @spec sync_horde_members!(timeout :: pos_integer()) :: :ok
  def sync_horde_members!(timeout \\ 5_000) do
    if not Smith.Connection.Topology.enabled?() do
      :ok
    else
      if Keyword.get(Smith.Connection.Topology.conn_cfg(), :sync_horde_members_on_boot, true) do
        reg = Smith.Connection.Registry.registry_name()
        sup = Smith.Connection.Supervisor.name()

        _ = Horde.Cluster.set_members(reg, horde_members(reg), timeout)
        _ = Horde.Cluster.set_members(sup, horde_members(sup), timeout)
        :ok
      else
        :ok
      end
    end
  rescue
    e ->
      Logger.warning("Smith.Connection.Handoff.sync_horde_members! skipped: #{Exception.message(e)}")
      :ok
  end

  @doc "Called by Observer on `nodeup`."
  @spec on_node_up(node()) :: :ok
  def on_node_up(node) do
    maybe_apply(Keyword.get(handoff_cfg(), :on_node_up_mfa), [node])
    _ = sync_horde_members!(5_000)
    :ok
  end

  @doc "Called by Observer on `nodedown`."
  @spec on_node_down(node()) :: :ok
  def on_node_down(node) do
    maybe_apply(Keyword.get(handoff_cfg(), :on_node_down_mfa), [node])
    :ok
  end

  defp handoff_cfg do
    Application.get_env(:service, Smith.Connection, [])
    |> Keyword.get(:handoff, [])
  end

  defp maybe_apply(nil, _), do: :ok

  defp maybe_apply({m, f, a}, extra) when is_atom(m) and is_atom(f) and is_list(a) do
    apply(m, f, a ++ extra)
    :ok
  rescue
    e ->
      Logger.error("Smith.Connection.Handoff MFA #{inspect({m, f, a})} failed: #{Exception.message(e)}")
      :ok
  end
end

defmodule Smith.Connection.Observer do
  @moduledoc """
  Subscribes to **`:net_kernel.monitor_nodes/2`** (`nodeup` / `nodedown`), logging, telemetry for Guard,
  invokes `Smith.Connection.Handoff`, and syncs Horde after a node joins.
  """

  use GenServer

  require Logger

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl true
  def init(_opts) do
    Smith.Connection.Handoff.ensure_handoff_table!()
    :ok = :net_kernel.monitor_nodes(true, node_type: :visible)
    Process.send_after(self(), :sync_horde, 250)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:sync_horde, state) do
    Smith.Connection.Handoff.sync_horde_members!()
    {:noreply, state}
  end

  def handle_info({:nodeup, node}, state) do
    emit(:up, node)
    Smith.Connection.Handoff.on_node_up(node)
    {:noreply, state}
  end

  def handle_info({:nodeup, node, _info}, state) do
    emit(:up, node)
    Smith.Connection.Handoff.on_node_up(node)
    {:noreply, state}
  end

  def handle_info({:nodedown, node}, state) do
    emit(:down, node)
    Smith.Connection.Handoff.on_node_down(node)
    {:noreply, state}
  end

  def handle_info({:nodedown, node, _info}, state) do
    emit(:down, node)
    Smith.Connection.Handoff.on_node_down(node)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Smith.Connection.Observer ignore: #{inspect(msg)}")
    {:noreply, state}
  end

  defp emit(event, node) do
    Logger.info("smith.connection cluster node #{event} #{node}")

    :telemetry.execute(
      [:smith, :cluster, :node],
      %{count: 1},
      %{event: event, node: node, visible: [Node.self() | Node.list()]}
    )

    :telemetry.execute(
      [:smith, :guard, :cluster, :topology],
      %{count: 1},
      %{event: event, node: node, visible_count: length([Node.self() | Node.list()])}
    )
  end
end

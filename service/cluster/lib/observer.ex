defmodule Service.Cluster.Observer do
  @moduledoc """
  Subscribes to Erlang node visibility (`:net_kernel.monitor_nodes/2`) and emits telemetry + handoff hooks.

  Requires distributed Erlang (`-name` / `-sname`, cookie) when clustering is enabled.
  """

  # TODO:
  # [ ] implement cluster observer:
  #     monitors node up/down events via :net_kernel.monitor_nodes
  #     publishes to NATS events.smith.cluster.{up|down}
  # [ ] implement cluster metrics:
  #     rice.cluster.node.count — active nodes
  #     rice.cluster.process.count — distributed processes
  #     forwarded to VictoriaMetrics via guard/metrics.ex

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
    :net_kernel.monitor_nodes(true, node_type: :visible)
    {:ok, %{}}
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    log_and_telemetry(:up, node)
    Service.Cluster.Handoff.on_node_up(node)
    {:noreply, state}
  end

  def handle_info({:nodeup, node, _info}, state) do
    log_and_telemetry(:up, node)
    Service.Cluster.Handoff.on_node_up(node)
    {:noreply, state}
  end

  def handle_info({:nodedown, node}, state) do
    log_and_telemetry(:down, node)
    Service.Cluster.Handoff.on_node_down(node)
    {:noreply, state}
  end

  def handle_info({:nodedown, node, _info}, state) do
    log_and_telemetry(:down, node)
    Service.Cluster.Handoff.on_node_down(node)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Service.Cluster.Observer ignore: #{inspect(msg)}")
    {:noreply, state}
  end

  defp log_and_telemetry(event, node) do
    Logger.info("cluster node #{event} #{node}")
    :telemetry.execute([:service, :cluster, :node], %{}, %{event: event, node: node})
  end
end

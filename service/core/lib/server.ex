defmodule Smith.Core.Server do
  @moduledoc """
  **GenServer** between Phoenix (Channels) and internal services (**Smith.Pipeline**, **Smith.Guard**).

  On `init/1`, a cluster snapshot is taken via **`Smith.Connection.Topology`**; external traffic is
  only allowed after **`Smith.Core.Readiness`** in **`Smith.Core.Application`**.
  """

  use GenServer

  require Logger

  @name __MODULE__

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, @name))
  end

  @doc "Asynchronously delivers a normalized command down the stack."
  @spec ingest(map()) :: :ok
  def ingest(envelope) when is_map(envelope) do
    GenServer.cast(@name, {:ingest, envelope})
  end

  @doc "Report a channel join (for telemetry / extensions)."
  @spec notify_join(String.t(), map()) :: :ok
  def notify_join(scope, meta) do
    GenServer.cast(@name, {:join, scope, meta})
  end

  @doc "Short snapshot for `/api/health`."
  @spec summary() :: map()
  def summary do
    GenServer.call(@name, :summary)
  end

  @impl true
  def init(_opts) do
    cluster =
      if Smith.Connection.Topology.enabled?() do
        Smith.Connection.Topology.nodes_status()
      else
        %{libcluster?: false, visible_count: 1, self: Node.self()}
      end

    Logger.info("smith.core.server: cluster snapshot #{inspect(Map.take(cluster, [:visible_count, :self, :libcluster?]))}")
    {:ok, %{cluster: cluster, ingests: 0}}
  end

  @impl true
  def handle_cast({:ingest, envelope}, state) do
    Phoenix.PubSub.broadcast(Smith.Core.PubSub, "smith:bridge:commands", {:command, envelope})
    {:noreply, %{state | ingests: state.ingests + 1}}
  end

  @impl true
  def handle_cast({:join, scope, meta}, state) do
    :telemetry.execute([:smith, :core, :channel_join], %{count: 1}, %{scope: scope, meta: meta})
    {:noreply, state}
  end

  @impl true
  def handle_call(:summary, _from, state) do
    {:reply,
     %{
       ingests: state.ingests,
       cluster: Map.take(state.cluster, [:visible_count, :self, :libcluster?])
     }, state}
  end

end

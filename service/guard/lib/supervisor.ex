defmodule Smith.Guard.Supervisor do
  @moduledoc """
  Root supervision tree for `:guard`: **infrastructure** (core, pipeline, cluster, connection),
  then **`Smith.Guard.ObserveStack`** — telemetry, metrics, alerts, **Watcher**, **Healer**, Metal.

  Inside `ObserveStack`, children run in order: Telemetry → Metrics → Alert → Watcher → Healer → Metal
  (`:rest_for_one`) so failures to the right of the first child do not tear down core/pipeline.
  """

  use Supervisor

  @rest_intensity 999_999_999
  @rest_period 1

  @observe_stack Smith.Guard.ObserveStack

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :permanent
    }
  end

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      core_stack(),
      pipeline_stack(),
      cluster_stack(),
      connection_stack(),
      observe_stack()
    ]

    Supervisor.init(children,
      strategy: :rest_for_one,
      max_restarts: @rest_intensity,
      max_seconds: @rest_period
    )
  end

  defp observe_stack do
    observe_children = [
      Smith.Guard.Telemetry,
      Smith.Guard.Metrics,
      Smith.Guard.Alert,
      Smith.Guard.Watcher,
      Smith.Guard.Healer,
      Smith.Guard.Metal
    ]

    %{
      id: @observe_stack,
      start:
        {Supervisor, :start_link,
         [
           observe_children,
           [
             strategy: :rest_for_one,
             name: @observe_stack,
             max_restarts: 500,
             max_seconds: 5
           ]
         ]},
      type: :supervisor,
      restart: :permanent
    }
  end

  defp core_stack do
    %{
      id: Service.Guard.CoreStack,
      start:
        {Supervisor, :start_link,
         [
           [
             Service.Telemetry,
             Service.ProcessRegistry,
             %{
               id: Service.Supervisor,
               start: {Supervisor, :start_link, [[], [strategy: :one_for_one, name: Service.Supervisor]]},
               type: :supervisor,
               restart: :permanent
             }
           ],
           [strategy: :one_for_one, name: Service.Guard.CoreStack]
         ]},
      type: :supervisor,
      restart: :permanent
    }
  end

  defp pipeline_stack do
    children =
      if pipeline_enabled?() do
        [
          {Smith.Pipeline.Nats, []},
          %{
            id: Smith.Pipeline.Media.State,
            start: {Agent, :start_link, [fn -> %{} end, [name: Smith.Pipeline.Media.State]]},
            restart: :permanent
          },
          {Smith.Pipeline, []}
        ]
      else
        []
      end

    %{
      id: Service.Guard.PipelineStack,
      start:
        {Supervisor, :start_link,
         [
           children,
           [strategy: :one_for_one, name: Service.Guard.PipelineStack]
         ]},
      type: :supervisor,
      restart: :permanent
    }
  end

  defp cluster_stack do
    %{
      id: Service.Guard.ClusterStack,
      start:
        {Supervisor, :start_link,
         [
           Smith.Connection.Topology.children(),
           [strategy: :one_for_one, name: Service.Guard.ClusterStack]
         ]},
      type: :supervisor,
      restart: :permanent
    }
  end

  defp connection_stack do
    finch = {Finch, name: Service.Finch, pools: %{default: [size: 32]}}

    %{
      id: Service.Guard.ConnectionStack,
      start:
        {Supervisor, :start_link,
         [
           [finch],
           [strategy: :one_for_one, name: Service.Guard.ConnectionStack]
         ]},
      type: :supervisor,
      restart: :permanent
    }
  end

  defp pipeline_enabled? do
    Application.get_env(:service, Service.Guard, [])
    |> Keyword.get(:pipeline_enabled, false)
  end
end

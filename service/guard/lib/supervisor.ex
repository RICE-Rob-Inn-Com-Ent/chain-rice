defmodule Service.Guard.Supervisor do
  @moduledoc """
  Rest-for-one root: ordered stacks for **core**, **pipeline**, **cluster**, **connection**, then alert → watcher → healer → metal.

  Uses a very high restart intensity so the VM keeps attempting recovery.
  """

  # TODO:
  # [ ] implement DynamicSupervisor for Go services:
  #     supervises: rice-web, rice-auth, rice-bench, rice-database,
  #                 rice-queue, rice-token Go binaries
  #     spawns each as Port (OS process)
  # [ ] implement restart policy:
  #     restart: :permanent — always restart on crash
  #     shutdown: RICE_GUARD_SHUTDOWN_TIMEOUT_MS env var
  # [ ] implement crash notification:
  #     on child crash → publish to NATS security.crash.{service}
  #     guard/ subscribes and alerts via alert.ex

  use Supervisor

  @rest_intensity 999_999_999
  @rest_period 1

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      Service.Guard.Telemetry,
      Service.Guard.Metrics,
      core_stack(),
      pipeline_stack(),
      cluster_stack(),
      connection_stack(),
      Service.Guard.Alert,
      Service.Guard.Watcher,
      Service.Guard.Healer,
      Service.Guard.Metal
    ]

    Supervisor.init(children,
      strategy: :rest_for_one,
      max_restarts: @rest_intensity,
      max_seconds: @rest_period
    )
  end

  defp core_stack do
    %{
      id: Service.Guard.CoreStack,
      start:
        {Supervisor, :start_link,
         [
           [
             Service.Telemetry,
             {Phoenix.PubSub, name: Service.PubSub},
             Service.ProcessRegistry,
             Service.Presence,
             Service.Endpoint,
             Service.Supervisor
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
        [{Service.Pipeline, []}]
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
           Service.Cluster.Topology.children(),
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

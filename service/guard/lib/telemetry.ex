defmodule Service.Guard.Telemetry do
  @moduledoc """
  Attaches `:telemetry` handlers for guard events (crash / restart / heal / heartbeat).
  """

  # TODO:
  # [ ] implement :telemetry event handlers:
  #     Phoenix request telemetry → OTel span
  #     Ecto query telemetry → OTel span
  #     Broadway message telemetry → OTel span
  # [ ] implement custom rice telemetry events:
  #     [:rice, :guard, :restart] — service restarted
  #     [:rice, :guard, :crash] — service crashed
  #     [:rice, :guard, :heal] — service healed
  #     all events forwarded to VictoriaMetrics

  use GenServer

  require Logger

  @events [
    [:service, :guard, :restart],
    [:service, :guard, :heal],
    [:service, :guard, :crash],
    [:service, :guard, :heartbeat]
  ]

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :telemetry.attach_many("service-guard", @events, &__MODULE__.dispatch/4, nil)
    {:ok, %{}}
  end

  @doc false
  def dispatch(event, measurements, metadata, _config) do
    Logger.debug("guard telemetry #{inspect(event)} #{inspect(measurements)} #{inspect(metadata)}")
    :ok
  end
end

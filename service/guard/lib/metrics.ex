defmodule Service.Guard.Metrics do
  @moduledoc """
  Healing-layer counters and histograms bridged to OpenTelemetry / VictoriaMetrics via OTLP exporter.

  Emits `:telemetry` events with measurements suitable for `Telemetry.Metrics` or OTel instruments.
  """

  # TODO:
  # [ ] implement OTel metrics for guard layer:
  #     rice.guard.restart.count — per service restart count
  #     rice.guard.crash.count — total crashes
  #     rice.guard.heal.duration — time to restore service
  #     rice.guard.circuit.state — open|closed|half_open
  # [ ] implement Telemetry event handlers:
  #     :telemetry.attach for all Phoenix/Ecto/Broadway events
  #     forwards to OTel MeterProvider

  use GenServer

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
    :telemetry.attach(
      "service-guard-metrics",
      [:service, :guard, :restart],
      &__MODULE__.on_restart/4,
      nil
    )

    :telemetry.attach(
      "service-guard-metrics-heal",
      [:service, :guard, :heal],
      &__MODULE__.on_heal/4,
      nil
    )

    {:ok, %{}}
  end

  def on_restart(_event, measurements, meta, _) do
    m = Map.merge(%{count: 1}, measurements)
    :telemetry.execute([:service, :guard, :metric, :restart], m, meta)
  end

  def on_heal(_event, measurements, meta, _) do
    m = Map.merge(%{duration_ms: 0}, measurements)
    :telemetry.execute([:service, :guard, :metric, :mttr], m, meta)
  end

  @doc "Record a restart for dashboards (restart counter, component tag)."
  @spec emit_restart(map()) :: :ok
  def emit_restart(meta \\ %{}) do
    :telemetry.execute([:service, :guard, :restart], %{count: 1}, meta)
  end

  @doc "Record heal cycle completion (MTTR sample)."
  @spec emit_heal(non_neg_integer(), map()) :: :ok
  def emit_heal(duration_ms, meta \\ %{}) when is_integer(duration_ms) do
    :telemetry.execute([:service, :guard, :heal], %{duration_ms: duration_ms}, meta)
  end
end

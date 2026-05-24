defmodule Smith.Guard.Metrics do
  @moduledoc """
  `Telemetry.Metrics` definitions for SMITH: counters, sums, last-value gauges, and latency
  distributions (histogram-style) for Broadway pipeline stages, NATS publishes, guard health,
  VM samples from `Smith.Guard.Telemetry`, and **Metal** host/GPU samples (`[:smith, :metal, :sample]`).

  When `config :service, Smith.Guard.Metrics, console_reporter: true`, a
  `Telemetry.Metrics.ConsoleReporter` child is started (dev / debugging).
  """

  use Supervisor

  @doc "Alias for **`Phoenix.LiveDashboard`** (`metrics: Smith.Guard.Metrics`)."
  def metrics, do: definitions()

  @doc "Metric definitions for reporters, dashboards, or tests."
  @spec definitions() :: [Telemetry.Metrics.t()]
  def definitions do
    [
      Telemetry.Metrics.counter("smith.guard.restarts.total",
        event_name: [:service, :guard, :restart],
        measurement: :count,
        description: "Service restarts observed by Guard"
      ),
      Telemetry.Metrics.summary("smith.guard.heal.duration",
        event_name: [:service, :guard, :heal],
        measurement: :duration_ms,
        unit: :millisecond,
        description: "Heal / MTTR duration (distribution / percentiles)"
      ),
      Telemetry.Metrics.sum("smith.guard.heal.duration_ms.total",
        event_name: [:service, :guard, :heal],
        measurement: :duration_ms,
        unit: :millisecond,
        description: "Cumulative heal time (sum of duration_ms)"
      ),
      Telemetry.Metrics.counter("smith.guard.errors.total",
        event_name: [:service, :guard, :crash],
        measurement: :count,
        description: "Crash / error signals for SMITH guard stack"
      ),
      Telemetry.Metrics.counter("smith.nats.published.total",
        event_name: [:smith, :nats, :published],
        measurement: :count,
        description: "NATS core publishes from Smith.Pipeline.Nats.pub/3"
      ),
      Telemetry.Metrics.distribution("smith.pipeline.broadway.processor.stop.duration",
        event_name: [:broadway, Smith.Pipeline, :processor, :stop],
        measurement: :duration,
        unit: {:native, :millisecond},
        description: "Broadway processor stop latency"
      ),
      Telemetry.Metrics.distribution("smith.pipeline.broadway.batcher.stop.duration",
        event_name: [:broadway, Smith.Pipeline, :batcher, :stop],
        measurement: :duration,
        unit: {:native, :millisecond},
        description: "Broadway batcher stop latency"
      ),
      Telemetry.Metrics.distribution("smith.pipeline.broadway.producer.stop.duration",
        event_name: [:broadway, Smith.Pipeline, :producer, :stop],
        measurement: :duration,
        unit: {:native, :millisecond},
        description: "Broadway producer stop latency"
      ),
      Telemetry.Metrics.last_value("smith.vm.memory.total.bytes",
        event_name: [:smith, :vm, :memory],
        measurement: :total,
        unit: :byte,
        description: "BEAM total memory"
      ),
      Telemetry.Metrics.last_value("smith.vm.run_queue.total",
        event_name: [:smith, :vm, :run_queue],
        measurement: :total,
        description: "Scheduler run queue length"
      ),
      Telemetry.Metrics.last_value("smith.metal.cpu_busy_percent",
        event_name: [:smith, :metal, :sample],
        measurement: :cpu_busy_percent,
        description: "Host/CPU busy 0–100 (cpu_sup or loadavg proxy)"
      ),
      Telemetry.Metrics.last_value("smith.metal.loadavg_1m",
        event_name: [:smith, :metal, :sample],
        measurement: :loadavg_1m,
        description: "1-minute load average (Linux /proc)"
      ),
      Telemetry.Metrics.last_value("smith.metal.beam_memory_total.bytes",
        event_name: [:smith, :metal, :sample],
        measurement: :beam_memory_total_bytes,
        unit: :byte,
        description: "BEAM total memory (Metal sample)"
      ),
      Telemetry.Metrics.last_value("smith.metal.gpu_utilization_percent",
        event_name: [:smith, :metal, :sample],
        measurement: :gpu_utilization_percent,
        description: "GPU utilization 0–100 (nvidia-smi or .rice-hardware)"
      ),
      Telemetry.Metrics.last_value("smith.metal.sage_gpu_ready",
        event_name: [:smith, :metal, :sample],
        measurement: :sage_gpu_ready,
        description: "1 if SAGE marks GPU ready in rice-hardware JSON"
      )
    ]
  end

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :permanent
    }
  end

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Supervisor
  def init(_opts) do
    children =
      if console_reporter?() do
        [{Telemetry.Metrics.ConsoleReporter, metrics: definitions()}]
      else
        []
      end

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp console_reporter? do
    Application.get_env(:service, Smith.Guard.Metrics, [])
    |> Keyword.get(:console_reporter, false)
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

  @doc "Record a crash signal for error sums / alerting."
  @spec emit_crash(map()) :: :ok
  def emit_crash(meta \\ %{}) do
    :telemetry.execute([:service, :guard, :crash], %{count: 1}, meta)
  end
end

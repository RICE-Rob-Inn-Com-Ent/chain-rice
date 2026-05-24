defmodule Smith.Guard.Telemetry do
  @moduledoc """
  Attaches `:telemetry` handlers for Guard + **pipeline** (Broadway) events and emits periodic **VM** samples.

  Handlers forward observations to `[:smith, :guard, :telemetry, …]` for dashboards and optionally
  create short OTel spans via `Smith.Guard.Tracer` (best-effort; never raises the emitter).
  """

  use GenServer

  require Logger

  @vm_tick :smith_guard_vm_tick

  @guard_events [
    [:service, :guard, :restart],
    [:service, :guard, :heal],
    [:service, :guard, :crash],
    [:service, :guard, :heartbeat]
  ]

  @broadway_stages [:processor, :batcher, :producer]
  @broadway_phases [:start, :stop]

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
    :telemetry.attach_many(
      "smith-guard-core",
      @guard_events,
      &__MODULE__.on_guard_event/4,
      nil
    )

    :telemetry.attach_many(
      "smith-guard-pipeline",
      broadway_events(),
      &__MODULE__.on_broadway_event/4,
      nil
    )

    schedule_vm()
    {:ok, %{vm_period_ms: vm_period_ms()}}
  end

  @impl true
  def handle_info(@vm_tick, state) do
    emit_vm_measurements()
    schedule_vm()
    {:noreply, state}
  end

  defp schedule_vm do
    Process.send_after(self(), @vm_tick, vm_period_ms())
  end

  defp vm_period_ms do
    Application.get_env(:service, Smith.Guard.Telemetry, [])
    |> Keyword.get(:vm_sample_period_ms, 5_000)
  end

  defp broadway_events do
    for stage <- @broadway_stages,
        phase <- @broadway_phases do
      [:broadway, Smith.Pipeline, stage, phase]
    end
  end

  @doc false
  def on_guard_event(event, measurements, metadata, _config) do
    :telemetry.execute(
      [:smith | tl(event)],
      measurements,
      Map.put(metadata, :source_event, event)
    )

    span_name = Enum.map_join(event, ".", &to_otel_segment/1)

    _ =
      Smith.Guard.Tracer.with_span(span_name, %{"rice.event" => inspect(event)}, fn ->
        Smith.Guard.Tracer.attributes(%{
          "rice.measurements" => inspect(measurements),
          "rice.metadata" => encode_metadata(metadata)
        })
      end)

    Logger.debug(fn -> "smith.guard.telemetry #{inspect(event)} #{inspect(measurements)}" end)

    :ok
  catch
    _, _ -> :ok
  end

  @doc false
  def on_broadway_event(event, measurements, metadata, _config) do
    :telemetry.execute(
      [:smith | tl(event)],
      measurements,
      Map.put(metadata, :source_event, event)
    )

    span_name = Enum.map_join(event, ".", &to_otel_segment/1)

    _ =
      Smith.Guard.Tracer.with_span(span_name, %{"rice.pipeline" => "Smith.Pipeline"}, fn ->
        Smith.Guard.Tracer.attributes(%{
          "rice.measurements" => inspect(measurements),
          "rice.metadata" => encode_metadata(metadata)
        })
      end)

    Logger.debug(fn -> "smith.pipeline.telemetry #{inspect(event)} #{inspect(measurements)}" end)

    :ok
  catch
    _, _ -> :ok
  end

  defp to_otel_segment(atom) when is_atom(atom), do: Atom.to_string(atom)
  defp to_otel_segment(bin) when is_binary(bin), do: bin
  defp to_otel_segment(other), do: inspect(other)

  defp encode_metadata(meta) when is_map(meta) do
    Jason.encode!(meta)
  rescue
    _ -> inspect(meta)
  end

  defp encode_metadata(meta), do: inspect(meta)

  defp emit_vm_measurements do
    mem = :erlang.memory()
    run_q = :erlang.statistics(:run_queue)

    :telemetry.execute(
      [:smith, :vm, :memory],
      %{
        total: Keyword.get(mem, :total, 0),
        processes: Keyword.get(mem, :processes, 0),
        binary: Keyword.get(mem, :binary, 0),
        ets: Keyword.get(mem, :ets, 0)
      },
      %{node: Node.self()}
    )

    :telemetry.execute([:smith, :vm, :run_queue], %{total: run_q}, %{node: Node.self()})
  end
end

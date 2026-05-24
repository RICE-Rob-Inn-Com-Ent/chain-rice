defmodule Smith.Guard.Watcher do
  @moduledoc """
  GenServer: periodic heartbeat plus `:telemetry` subscription to analyze failures and latency in
  Broadway (`Smith.Pipeline`). When thresholds are exceeded — `Smith.Guard.Alert.notify_incident/1` and
  `GenServer.cast` to `Smith.Guard.Healer`.
  """

  use GenServer

  @telemetry_prefix :smith_guard_watcher

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
    interval = poll_interval_ms()
    :timer.send_interval(interval, :tick)

    if watcher_enabled?() do
      attach_telemetry()
    end

    {:ok,
     %{
       tick: 0,
       crash_ts: [],
       last_breach_ms: 0
     }}
  end

  @impl true
  def terminate(_reason, _s) do
    detach_telemetry()
    :ok
  end

  @impl true
  def handle_info(:tick, %{tick: n} = s) do
    :telemetry.execute([:service, :guard, :heartbeat], %{}, %{tick: n})
    Smith.Guard.Alert.heartbeat()
    {:noreply, %{s | tick: n + 1}}
  end

  @impl true
  def handle_cast({:telemetry, event, measurements, metadata}, s) do
    now = System.monotonic_time(:millisecond)
    s = %{s | crash_ts: prune_window(s.crash_ts, now)}

    cond do
      match?([:service, :guard, :crash], event) ->
        handle_crash(s, now, metadata)

      broadway_stop?(event) ->
        handle_latency(s, now, event, measurements, metadata)

      true ->
        {:noreply, s}
    end
  end

  defp broadway_stop?(list) when is_list(list) do
    case list do
      [:broadway, Smith.Pipeline, stage, :stop] when stage in [:processor, :batcher, :producer] ->
        true

      _ ->
        false
    end
  end

  defp broadway_stop?(_), do: false

  defp handle_crash(s, now, meta) do
    threshold = watcher_cfg(:error_threshold, 5)
    window_ms = watcher_cfg(:error_window_ms, 60_000)
    crash_ts = [now | s.crash_ts] |> Enum.filter(fn t -> now - t <= window_ms end)
    s = %{s | crash_ts: crash_ts}
    meta_map = if is_map(meta), do: meta, else: %{raw: inspect(meta)}

    if length(crash_ts) >= threshold do
      breach(s, :error_storm, %{
        summary: "≥#{threshold} crash signals in #{div(window_ms, 1000)}s",
        meta: meta_map
      })
    else
      {:noreply, s}
    end
  end

  defp handle_latency(s, now, event, measurements, metadata) do
    duration_native = Map.get(measurements, :duration)

    if is_integer(duration_native) do
      ms = System.convert_time_unit(duration_native, :native, :millisecond)
      limit = watcher_cfg(:latency_threshold_ms, 10_000)

      if ms >= limit do
        meta_base = if is_map(metadata), do: metadata, else: %{raw: inspect(metadata)}

        breach(s, :pipeline_latency, %{
          summary: "Broadway stage slow: #{inspect(event)} ≈ #{ms}ms (threshold #{limit}ms)",
          meta:
            Map.merge(meta_base, %{
              stage: inspect(event),
              duration_ms: ms
            })
        })
      else
        {:noreply, s}
      end
    else
      {:noreply, s}
    end
  end

  defp breach(s, kind, %{summary: summary, meta: meta}) do
    now = System.monotonic_time(:millisecond)
    cooldown = watcher_cfg(:breach_cooldown_ms, 30_000)

    if now - s.last_breach_ms < cooldown do
      {:noreply, s}
    else
      Smith.Guard.Alert.notify_incident(%{
        kind: kind,
        severity: :warning,
        summary: summary,
        meta: meta
      })

      component = watcher_cfg(:healer_component, {:smith, :guard_pipeline})

      GenServer.cast(
        Smith.Guard.Healer,
        {:maybe_heal, component, {:watcher_breach, kind, summary}}
      )

      s = %{s | last_breach_ms: now}
      s = if kind == :error_storm, do: %{s | crash_ts: []}, else: s
      {:noreply, s}
    end
  end

  defp prune_window(ts_list, now) do
    window = watcher_cfg(:error_window_ms, 60_000)
    Enum.filter(ts_list, fn t -> now - t <= window end)
  end

  defp attach_telemetry do
    me = self()

    events = [
      {[:service, :guard, :crash], :crash},
      {[:broadway, Smith.Pipeline, :processor, :stop], :broadway_processor},
      {[:broadway, Smith.Pipeline, :batcher, :stop], :broadway_batcher},
      {[:broadway, Smith.Pipeline, :producer, :stop], :broadway_producer}
    ]

    for {ev, tag} <- events do
      id = {@telemetry_prefix, tag}

      :telemetry.attach(
        id,
        ev,
        fn event, measurements, metadata, _config ->
          GenServer.cast(me, {:telemetry, event, measurements, metadata})
        end,
        nil
      )
    end

    :ok
  end

  defp detach_telemetry do
    for tag <- [:crash, :broadway_processor, :broadway_batcher, :broadway_producer] do
      _ = :telemetry.detach({@telemetry_prefix, tag})
    end

    :ok
  end

  defp poll_interval_ms do
    Keyword.get(guard_cfg(), :watcher_poll_ms, 5_000)
  end

  defp guard_cfg, do: Application.get_env(:service, Service.Guard, [])

  defp watcher_cfg(key, default) do
    Application.get_env(:service, Smith.Guard.Watcher, [])
    |> Keyword.get(key, default)
  end

  defp watcher_enabled? do
    Application.get_env(:service, Smith.Guard.Watcher, [])
    |> Keyword.get(:enabled, true)
  end
end

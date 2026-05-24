defmodule Smith.Guard.Alert do
  @moduledoc """
  Builds structured incidents for SMITH Guard and publishes them to NATS via `Smith.Pipeline.Nats`
  (Gnat) — default subject `rice.bard.guard.incidents` for BARD / `.rice OS`.

  Dead-man: heartbeat from `Smith.Guard.Watcher`; when the signal stops — incident + crash metric.
  """

  use GenServer

  require Logger

  @schema "smith.guard.incident/v1"

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

  @doc "Update heartbeat for the dead-man switch."
  def heartbeat do
    if pid = Process.whereis(__MODULE__), do: GenServer.cast(pid, :heartbeat)
    :ok
  end

  @doc "Escalate after repeated failures (Healer and similar)."
  def notify_escalation(payload) when is_map(payload) do
    GenServer.cast(__MODULE__, {:escalate, payload})
  end

  @doc "Incident (severity: :info | :warning | :critical)."
  def notify_incident(attrs) when is_map(attrs) do
    GenServer.cast(__MODULE__, {:incident, attrs})
  end

  @doc "Build a JSON-friendly incident document (without publishing)."
  @spec build_incident(map()) :: map()
  def build_incident(attrs) when is_map(attrs) do
    kind = Map.get(attrs, :kind, :unknown)
    sev = Map.get(attrs, :severity, :warning)
    summary = Map.get(attrs, :summary) || Map.get(attrs, :message) || inspect(kind)
    meta = Map.get(attrs, :meta, %{})

    %{
      "schema" => @schema,
      "kind" => to_string(kind),
      "severity" => to_string(sev),
      "summary" => summary,
      "ts_ms" => System.system_time(:millisecond),
      "node" => to_string(Node.self()),
      "meta" => normalize_meta(meta)
    }
  end

  defp normalize_meta(m) when is_map(m), do: m
  defp normalize_meta(m), do: %{"raw" => inspect(m)}

  @impl true
  def init(_opts) do
    schedule_deadman()
    {:ok, %{last_heartbeat: System.monotonic_time(:second), rates: %{}}}
  end

  @impl true
  def handle_cast(:heartbeat, s) do
    {:noreply, %{s | last_heartbeat: System.monotonic_time(:second)}}
  end

  def handle_cast({:escalate, payload}, s) do
    key = throttle_key(:escalation)
    {allow, s1} = allow_emit?(s, key)

    if allow do
      incident =
        build_incident(%{
          kind: :escalation,
          severity: :critical,
          summary: "Guard escalation: #{Map.get(payload, :type, :unknown)}",
          meta: payload
        })

      Logger.error("guard escalation #{inspect(payload)}")
      _ = publish_json(incident_topic(), incident)
      _ = publish_json(legacy_alert_topic(), Map.put(payload, :ts, System.system_time(:millisecond)))
    end

    {:noreply, s1}
  end

  def handle_cast({:incident, attrs}, s) do
    key = throttle_key(Map.get(attrs, :kind, :incident))
    {allow, s1} = allow_emit?(s, key)

    if allow do
      incident = build_incident(attrs)
      _ = publish_json(incident_topic(), incident)
      log_severity(Map.get(attrs, :severity, :warning), incident["summary"])
    end

    {:noreply, s1}
  end

  @impl true
  def handle_info(:deadman, s) do
    now = System.monotonic_time(:second)
    gap = now - s.last_heartbeat

    if gap > deadman_grace_s() do
      Logger.error("guard dead man switch: no heartbeat for #{gap}s")
      Smith.Guard.Metrics.emit_crash(%{type: :deadman_switch, gap_s: gap})
      GenServer.cast(self(), {:incident, deadman_incident(gap)})
    end

    schedule_deadman()
    {:noreply, s}
  end

  defp deadman_incident(gap) do
    %{
      kind: :deadman_switch,
      severity: :critical,
      summary: "Guard heartbeat missing for #{gap}s",
      meta: %{gap_s: gap}
    }
  end

  defp publish_json(nil, _doc), do: :ok

  defp publish_json(topic, doc) when is_binary(topic) do
    if nats_ready?() do
      case Jason.encode(doc) do
        {:ok, bin} -> Smith.Pipeline.Nats.pub(topic, bin)
        _ -> :ok
      end
    else
      :ok
    end
  end

  defp allow_emit?(%{rates: rates} = s, key) do
    now = System.monotonic_time(:millisecond)
    window = alert_cfg(:rate_limit_window_ms, 60_000)
    max_n = alert_cfg(:rate_limit_max_per_window, 30)
    stamps = rates |> Map.get(key, []) |> Enum.filter(fn t -> now - t <= window end)

    if length(stamps) >= max_n do
      {false, %{s | rates: Map.put(rates, key, stamps)}}
    else
      {true, %{s | rates: Map.put(rates, key, [now | stamps])}}
    end
  end

  defp throttle_key(:escalation), do: "escalation"
  defp throttle_key(k) when is_atom(k), do: Atom.to_string(k)
  defp throttle_key(k) when is_binary(k), do: k
  defp throttle_key(k), do: inspect(k)

  defp log_severity(:critical, msg), do: Logger.error(msg)
  defp log_severity(:warning, msg), do: Logger.warning(msg)
  defp log_severity(_, msg), do: Logger.info(msg)

  defp schedule_deadman do
    Process.send_after(self(), :deadman, deadman_check_ms())
  end

  defp deadman_check_ms, do: Keyword.get(guard_cfg(), :deadman_check_ms, 15_000)
  defp deadman_grace_s, do: Keyword.get(guard_cfg(), :deadman_grace_s, 60)
  defp guard_cfg, do: Application.get_env(:service, Service.Guard, [])

  defp alert_cfg(key, default) do
    Application.get_env(:service, Smith.Guard.Alert, [])
    |> Keyword.get(key, default)
  end

  defp incident_topic do
    smith = Application.get_env(:service, Smith.Guard.Alert, [])

    Keyword.get(smith, :incident_topic) ||
      Keyword.get(guard_cfg(), :bard_incident_topic) ||
      "rice.bard.guard.incidents"
  end

  defp legacy_alert_topic, do: Keyword.get(guard_cfg(), :alert_topic)

  defp nats_ready? do
    conn = Smith.Pipeline.Nats.connection_name()
    Process.whereis(conn) != nil
  end
end

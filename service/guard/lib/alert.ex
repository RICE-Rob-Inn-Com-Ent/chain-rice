defmodule Service.Guard.Alert do
  @moduledoc """
  SLO breach signals, dead-man switch, and optional NATS publish for paging integrations.

  Heartbeats come from `Service.Guard.Watcher`; if they stop, `deadman` fires.
  """

  # TODO:
  # [ ] implement alerting:
  #     alert on crash: publishes to NATS alerts.guard.crash.{service}
  #     alert on circuit open: NATS alerts.guard.circuit.open
  #     alert on cascade: NATS alerts.guard.cascade
  # [ ] implement alert throttling:
  #     max alerts per minute from RICE_GUARD_ALERT_RATE env var
  #     prevents alert storm on cascade failure
  # [ ] implement alert severity levels:
  #     info, warning, critical — based on crash frequency
  #     RICE_GUARD_ALERT_THRESHOLD controls severity mapping

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

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Escalate after repeated failures or circuit events."
  def notify_escalation(payload) when is_map(payload) do
    GenServer.cast(__MODULE__, {:escalate, payload})
  end

  @impl true
  def init(_opts) do
    schedule_deadman()
    {:ok, %{last_heartbeat: System.monotonic_time(:second)}}
  end

  @impl true
  def handle_cast(:heartbeat, s) do
    {:noreply, %{s | last_heartbeat: System.monotonic_time(:second)}}
  end

  def handle_cast({:escalate, payload}, s) do
    Logger.error("guard escalation #{inspect(payload)}")
    publish_alert(Map.put(payload, :ts, System.system_time(:millisecond)))
    {:noreply, s}
  end

  @impl true
  def handle_info(:deadman, s) do
    now = System.monotonic_time(:second)
    gap = now - s.last_heartbeat

    if gap > deadman_grace_s() do
      Logger.error("guard dead man switch: no heartbeat for #{gap}s")
      publish_alert(%{type: :deadman_switch, gap_s: gap})
      :telemetry.execute([:service, :guard, :crash], %{}, %{type: :deadman_switch, gap_s: gap})
    end

    schedule_deadman()
    {:noreply, s}
  end

  defp schedule_deadman do
    Process.send_after(self(), :deadman, deadman_check_ms())
  end

  defp deadman_check_ms, do: Keyword.get(guard_cfg(), :deadman_check_ms, 15_000)
  defp deadman_grace_s, do: Keyword.get(guard_cfg(), :deadman_grace_s, 60)
  defp guard_cfg, do: Application.get_env(:service, Service.Guard, [])

  defp publish_alert(payload) do
    topic = Keyword.get(guard_cfg(), :alert_topic)
    conn = Keyword.get(Application.get_env(:service, Service.Pipeline.NATS, []), :name)

    if topic && conn && Process.whereis(conn) do
      case Jason.encode(payload) do
        {:ok, bin} -> _ = Gnat.pub(conn, topic, bin)
        _ -> :ok
      end
    end

    :ok
  end
end

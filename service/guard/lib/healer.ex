defmodule Service.Guard.Healer do
  @moduledoc """
  Backoff between recovery attempts, failure counting, and escalation via `Service.Guard.Alert`.
  """

  # TODO:
  # [ ] implement self-healing logic:
  #     handle_info({:DOWN, ...}) — process died, restart it
  #     handle_info({:EXIT, ...}) — linked process exited
  # [ ] implement cascading failure prevention:
  #     if >RICE_GUARD_CASCADE_THRESHOLD services fail simultaneously
  #     → circuit breaker: stop all restarts, alert operator
  #     circuit opens for RICE_GUARD_CIRCUIT_TIMEOUT_S seconds
  # [ ] implement heal event publishing:
  #     every restart → publish to NATS events.smith.heal.{service}

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
    {:ok, %{failures: 0, backoff_ms: initial_backoff_ms()}}
  end

  @impl true
  def handle_cast({:maybe_heal, component, reason}, state) do
    Service.Guard.Metrics.emit_restart(%{component: component, reason: inspect(reason)})
    failures = state.failures + 1

    if failures >= max_failures() do
      :telemetry.execute([:service, :guard, :crash], %{}, %{component: component, reason: reason})
      Service.Guard.Alert.notify_escalation(%{type: :escalation, component: component, reason: reason})
      {:noreply, %{state | failures: 0, backoff_ms: initial_backoff_ms()}}
    else
      t0 = System.monotonic_time(:millisecond)
      next_backoff = min(state.backoff_ms * 2, max_backoff_ms())

      Process.send_after(
        self(),
        {:recover, component, t0},
        state.backoff_ms
      )

      {:noreply, %{state | failures: failures, backoff_ms: next_backoff}}
    end
  end

  @impl true
  def handle_info({:recover, component, t0}, state) do
    dt = System.monotonic_time(:millisecond) - t0
    Service.Guard.Metrics.emit_heal(abs(dt), %{component: component})
    {:noreply, %{state | failures: max(0, state.failures - 1), backoff_ms: initial_backoff_ms()}}
  end

  defp initial_backoff_ms, do: Keyword.get(guard_cfg(), :healer_initial_backoff_ms, 500)
  defp max_backoff_ms, do: Keyword.get(guard_cfg(), :healer_max_backoff_ms, 60_000)
  defp max_failures, do: Keyword.get(guard_cfg(), :healer_max_failures, 5)
  defp guard_cfg, do: Application.get_env(:service, Service.Guard, [])
end

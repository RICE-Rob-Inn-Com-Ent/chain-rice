defmodule Smith.Guard.Healer do
  @moduledoc """
  SMITH self-healing core: accepts `{:maybe_heal, component, reason}` (Watcher, Metal/Odin, …),
  applies backoff, and runs **healing strategies** after a delay:

  * **pipeline** — `Supervisor.terminate_child/2` on `Smith.Pipeline` (Broadway is restarted by parent `Service.Guard.PipelineStack`);
  * **queues** — JSON `drain` command over NATS (subject from config) so mesh / workers can flush backlog;
  * **KING / auto-repair** — HTTP POST to `king_repair_base_url` + `king_repair_path` (Finch).

  Escalation threshold and backoff come from `config :service, Service.Guard`.
  """

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

  @doc "Healing request: `component` (area), `reason` (tuple or term)."
  @spec maybe_heal(term(), term()) :: :ok
  def maybe_heal(component, reason) do
    GenServer.cast(__MODULE__, {:maybe_heal, component, reason})
  end

  @impl true
  def init(_opts) do
    {:ok, %{failures: 0, backoff_ms: initial_backoff_ms()}}
  end

  @impl true
  def handle_cast({:maybe_heal, component, reason}, state) do
    Smith.Guard.Metrics.emit_restart(%{component: component, reason: inspect(reason)})
    failures = state.failures + 1

    if failures >= max_failures() do
      outcomes = run_strategies(component, reason, :escalation)
      Smith.Guard.Metrics.emit_crash(%{component: component, reason: reason})
      Smith.Guard.Alert.notify_escalation(%{type: :escalation, component: component, reason: reason, heal: outcomes})
      {:noreply, %{state | failures: 0, backoff_ms: initial_backoff_ms()}}
    else
      t0 = System.monotonic_time(:millisecond)
      next_backoff = min(state.backoff_ms * 2, max_backoff_ms())

      Process.send_after(
        self(),
        {:recover, component, reason, t0},
        state.backoff_ms
      )

      {:noreply, %{state | failures: failures, backoff_ms: next_backoff}}
    end
  end

  @impl true
  def handle_info({:recover, component, reason, t0}, state) do
    dt = System.monotonic_time(:millisecond) - t0
    outcomes = run_strategies(component, reason, :recover)
    Smith.Guard.Metrics.emit_heal(abs(dt), %{component: component, outcomes: inspect(outcomes)})
    _ = publish_heal_event(component, reason, outcomes)
    {:noreply, %{state | failures: max(0, state.failures - 1), backoff_ms: initial_backoff_ms()}}
  end

  @doc false
  def run_strategies(component, reason, phase \\ :recover) do
    actions = plan_actions(component, reason, phase)
    results = Enum.map(actions, &apply_action/1)

    :telemetry.execute(
      [:service, :guard, :heal_strategies],
      %{count: length(results)},
      %{phase: phase, results: results}
    )

    results
  end

  defp plan_actions(component, reason, phase) do
    []
    |> maybe_add(:restart_pipeline_broadway, restart_pipeline?(component, reason, phase), {component, reason})
    |> maybe_add(:signal_queue_drain, signal_queue?(component, reason, phase), {component, reason})
    |> maybe_add(:king_repair_http, king_repair?(component, reason, phase), {component, reason, phase})
    |> Enum.reverse()
  end

  defp maybe_add(list, tag, true, arg), do: [{tag, arg} | list]
  defp maybe_add(list, _tag, false, _arg), do: list

  defp restart_pipeline?(component, reason, _phase) do
    pipeline_up?() and match?({:watcher_breach, _, _}, reason) and component_match_pipeline?(component)
  end

  defp component_match_pipeline?({:smith, :guard_pipeline}), do: true
  defp component_match_pipeline?({:smith, _}), do: true
  defp component_match_pipeline?(_), do: false

  defp signal_queue?(component, reason, _phase) do
    case healer_cfg(:heal_queue_control_topic) do
      topic when is_binary(topic) and topic != "" ->
        nats_ready?() and
          (match?({:watcher_breach, _, _}, reason) or match?({:odin, _}, component))

      _ ->
        false
    end
  end

  defp king_repair?(component, reason, phase) do
    base = king_repair_base_url()
    base != nil and base != "" and (phase == :escalation or match?({:watcher_breach, _, _}, reason) or match?({:odin, _}, component))
  end

  defp pipeline_up? do
    Process.whereis(Service.Guard.PipelineStack) && Process.whereis(Smith.Pipeline)
  end

  defp apply_action({:restart_pipeline_broadway, {component, reason}}) do
    sup = Service.Guard.PipelineStack

    case Process.whereis(sup) do
      nil ->
        {:restart_pipeline, :skipped, :no_supervisor}

      _pid ->
        case Supervisor.terminate_child(sup, Smith.Pipeline) do
          :ok -> {:restart_pipeline, :ok, :terminated}
          {:error, :not_found} -> {:restart_pipeline, :skipped, :not_running}
          {:error, err} -> {:restart_pipeline, :error, err}
        end
    end
  rescue
    e -> {:restart_pipeline, :error, e}
  end

  defp apply_action({:signal_queue_drain, {component, reason}}) do
    topic = healer_cfg(:heal_queue_control_topic)

    payload =
      Jason.encode!(%{
        "op" => "drain",
        "source" => "smith.guard.healer",
        "component" => inspect(component),
        "reason" => inspect(reason),
        "ts_ms" => System.system_time(:millisecond)
      })

    case Smith.Pipeline.Nats.pub(topic, payload) do
      :ok -> {:queue_drain_signal, :ok, topic}
      err -> {:queue_drain_signal, :error, err}
    end
  end

  defp apply_action({:king_repair_http, {component, reason, phase}}) do
    finch = healer_cfg(:finch, Service.Finch)

    if Process.whereis(finch) == nil do
      {:king_repair, :skipped, :finch_down}
    else
      base = king_repair_base_url()
      path = healer_cfg(:king_repair_path, "/mesh/auto-repair")
      url = String.trim_trailing(base, "/") <> path

      body =
        Jason.encode!(%{
          "source" => "smith.guard.healer",
          "phase" => to_string(phase),
          "component" => inspect(component),
          "reason" => inspect(reason)
        })

      req = Finch.build(:post, url, [{"content-type", "application/json"}], body)

      case Finch.request(finch, req, receive_timeout: healer_cfg(:king_repair_timeout_ms, 8_000)) do
        {:ok, %Finch.Response{status: s}} when s in 200..299 ->
          {:king_repair, :ok, s}

        {:ok, %Finch.Response{status: s}} ->
          {:king_repair, :http_error, s}

        {:error, err} ->
          {:king_repair, :error, err}
      end
    end
  rescue
    e -> {:king_repair, :error, e}
  end

  defp publish_heal_event(component, reason, outcomes) do
    topic = healer_cfg(:heal_event_topic)

    if is_binary(topic) and topic != "" and nats_ready?() do
      bin =
        Jason.encode!(%{
          "op" => "heal",
          "component" => inspect(component),
          "reason" => inspect(reason),
          "outcomes" => inspect(outcomes),
          "ts_ms" => System.system_time(:millisecond)
        })

      Smith.Pipeline.Nats.pub(topic, bin)
    else
      :ok
    end
  end

  defp nats_ready? do
    conn = Smith.Pipeline.Nats.connection_name()
    Process.whereis(conn) != nil
  end

  defp king_repair_base_url do
    healer_cfg(:king_repair_base_url) || ""
  end

  defp healer_cfg(key, default \\ nil) do
    Application.get_env(:service, Smith.Guard.Healer, [])
    |> Keyword.get(key, default)
  end

  defp initial_backoff_ms, do: Keyword.get(guard_cfg(), :healer_initial_backoff_ms, 500)
  defp max_backoff_ms, do: Keyword.get(guard_cfg(), :healer_max_backoff_ms, 60_000)
  defp max_failures, do: Keyword.get(guard_cfg(), :healer_max_failures, 5)
  defp guard_cfg, do: Application.get_env(:service, Service.Guard, [])
end

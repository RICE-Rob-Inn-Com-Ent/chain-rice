defmodule Service.Guard.Watcher do
  @moduledoc """
  Periodic health signal + optional supervision introspection hooks for crash detection.

  Emits `:telemetry` `[:service, :guard, :heartbeat]` and pings `Service.Guard.Alert` for the dead-man switch.
  """

  # TODO:
  # [ ] implement GenServer watcher:
  #     polls health endpoints of all Go services
  #     interval from RICE_GUARD_HEALTH_INTERVAL_S env var
  # [ ] implement unhealthy detection:
  #     3 consecutive failures → restart via supervisor
  #     failure count from RICE_GUARD_FAILURE_THRESHOLD env var
  # [ ] implement Odin vendor process watching:
  #     watches BARD Odin hardware daemon (rice-bard binary)
  #     GPU crash → restart daemon → notify via NATS

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
    interval = poll_interval_ms()
    :timer.send_interval(interval, :tick)
    {:ok, %{tick: 0}}
  end

  @impl true
  def handle_info(:tick, %{tick: n} = s) do
    :telemetry.execute([:service, :guard, :heartbeat], %{}, %{tick: n})
    if Process.whereis(Service.Guard.Alert), do: GenServer.cast(Service.Guard.Alert, :heartbeat)
    {:noreply, %{s | tick: n + 1}}
  end

  defp poll_interval_ms do
    Application.get_env(:service, Service.Guard, [])
    |> Keyword.get(:watcher_poll_ms, 5_000)
  end
end

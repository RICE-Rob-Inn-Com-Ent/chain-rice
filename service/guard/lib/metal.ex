defmodule Service.Guard.Metal do
  @moduledoc """
  Monitors BARD Odin-related OS ports (GPU/audio/video sidecars) and forwards failures to the healer.

  Configure `odin_ports` with a list of `port()` references (or use `attach/1` after startup).
  """

  # TODO:
  # [ ] implement hardware process supervision:
  #     supervises Odin vendor processes (BARD hardware daemon)
  #     GPU daemon, audio daemon, hardware watcher
  # [ ] implement GPU state monitoring:
  #     reads .rice-hardware.json — updated by Odin daemon
  #     on GPU process crash → halt inference → notify SAGE
  #     SAGE falls back to CPU inference on GPU unavailable
  # [ ] implement port communication:
  #     Elixir Port wraps Odin binary
  #     typed message structs via msgpack

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
    ports =
      Keyword.get(guard_cfg(), :odin_ports, [])
      |> Enum.filter(&is_port/1)

    refs = Enum.map(ports, &monitor_port/1)
    {:ok, %{monitors: refs}}
  end

  defp monitor_port(p) when is_port(p) do
    if function_exported?(Port, :monitor, 1) do
      Port.monitor(p)
    else
      :erlang.monitor(:port, p)
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :port, port, reason}, state) do
    if Process.whereis(Service.Guard.Healer) do
      GenServer.cast(Service.Guard.Healer, {:maybe_heal, {:odin, port}, reason})
    end

    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp guard_cfg, do: Application.get_env(:service, Service.Guard, [])
end

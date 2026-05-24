defmodule Smith.Guard.Metal do
  @moduledoc """
  Hardware metrics for `.rice` / SAGE: periodic samples of **CPU**, **memory**, and **GPU** (when present),
  plus Odin port monitoring for BARD.

  * **CPU** — first `:cpu_sup` from **`:os_mon`** (`Application.ensure_all_started/1`);
    if unavailable — **load average** from `/proc/loadavg` (Linux) as a coarse load signal.
  * **Memory** — `:erlang.memory/0` (BEAM); when `/proc/meminfo` exists — **MemAvailable/MemTotal**.
  * **GPU** — short **`nvidia-smi`** run (when enabled in config); otherwise JSON **`.rice-hardware.json`**
    (path from config / `~/.rice-hardware.json`) for SAGE hints.

  Telemetry event: `[:smith, :metal, :sample]` (see `Smith.Guard.Metrics`).
  """

  use GenServer

  require Logger

  @tick :smith_guard_metal_tick

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
    _ = Application.ensure_all_started(:os_mon)

    ports =
      Keyword.get(guard_cfg(), :odin_ports, [])
      |> Enum.filter(&is_port/1)

    refs = Enum.map(ports, &monitor_port/1)
    schedule_sample()
    {:ok, %{monitors: refs}}
  end

  @impl true
  def handle_info(@tick, state) do
    sample = collect_sample()
    :telemetry.execute([:smith, :metal, :sample], sample.measurements, sample.metadata)
    schedule_sample()
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :port, port, reason}, state) do
    if Process.whereis(Smith.Guard.Healer) do
      GenServer.cast(Smith.Guard.Healer, {:maybe_heal, {:odin, port}, reason})
    end

    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  @doc false
  def collect_sample do
    beam = :erlang.memory()
    beam_total = Keyword.get(beam, :total, 0)
    beam_processes = Keyword.get(beam, :processes, 0)
    run_q = :erlang.statistics(:run_queue)

    cpu_busy = cpu_busy_percent()
    load1 = loadavg_1m()
    {mem_avail_ratio, mem_avail_bytes} = host_mem_available()

    hw = rice_hardware_map()
    {gpu_util, gpu_mem_used_mib, gpu_mem_total_mib, gpu_ok} = gpu_metrics(hw)
    sage_gpu_ok = sage_gpu_ready?(hw)

    measurements = %{
      cpu_busy_percent: cpu_busy,
      loadavg_1m: load1,
      beam_memory_total_bytes: beam_total,
      beam_memory_processes_bytes: beam_processes,
      scheduler_run_queue: run_q,
      host_mem_available_ratio: mem_avail_ratio,
      host_mem_available_bytes: mem_avail_bytes,
      gpu_utilization_percent: gpu_util,
      gpu_memory_used_mib: gpu_mem_used_mib,
      gpu_memory_total_mib: gpu_mem_total_mib,
      gpu_probe_ok: if(gpu_ok, do: 1, else: 0),
      sage_gpu_ready: if(sage_gpu_ok, do: 1, else: 0)
    }

    meta = %{
      node: Node.self(),
      rice_hardware_keys: Map.keys(hw),
      source: "smith.guard.metal"
    }

    %{measurements: measurements, metadata: meta}
  end

  defp schedule_sample do
    Process.send_after(self(), @tick, sample_period_ms())
  end

  defp sample_period_ms do
    Application.get_env(:service, Smith.Guard.Metal, [])
    |> Keyword.get(:sample_period_ms, 3_000)
  end

  defp monitor_port(p) when is_port(p) do
    if function_exported?(Port, :monitor, 1) do
      Port.monitor(p)
    else
      :erlang.monitor(:port, p)
    end
  end

  defp guard_cfg, do: Application.get_env(:service, Service.Guard, [])

  defp metal_cfg(key, default) do
    Application.get_env(:service, Smith.Guard.Metal, [])
    |> Keyword.get(key, default)
  end

  defp cpu_busy_percent do
    case cpu_sup_util_percent() do
      {:ok, v} when is_number(v) -> clamp_percent(v)
      _ -> loadavg_as_pseudo_cpu_percent()
    end
  end

  defp cpu_sup_util_percent do
    cond do
      function_exported?(:cpu_sup, :util, 0) ->
        case :cpu_sup.util() do
          n when is_number(n) -> {:ok, n * 1.0}
          {n, _, _} when is_number(n) -> {:ok, n * 1.0}
          _ -> :error
        end

      function_exported?(:cpu_sup, :util, 1) ->
        case :cpu_sup.util([:average]) do
          n when is_number(n) -> {:ok, n * 1.0}
          {n, _, _} when is_number(n) -> {:ok, n * 1.0}
          _ -> :error
        end

      true ->
        :error
    end
  catch
    :exit, _ -> :error
    :throw, _ -> :error
  end

  defp loadavg_1m do
    case File.read("/proc/loadavg") do
      {:ok, line} ->
        first =
          line
          |> String.split(" ", parts: 2)
          |> List.first()

        case first do
          s when is_binary(s) ->
            case parse_float(s) do
              {:ok, x} -> x
              _ -> 0.0
            end

          _ ->
            0.0
        end

      {:error, _} ->
        0.0
    end
  end

  defp loadavg_as_pseudo_cpu_percent do
    la = loadavg_1m()
    sched = max(1, :erlang.system_info(:schedulers_online))
    clamp_percent(la * 100.0 / sched)
  end

  defp host_mem_available do
    case File.read("/proc/meminfo") do
      {:ok, text} ->
        avail = meminfo_kb(text, "MemAvailable:")
        total = meminfo_kb(text, "MemTotal:")
        ratio = if total > 0 and avail >= 0, do: avail / total, else: -1.0
        bytes = if avail >= 0, do: round(avail * 1024), else: -1
        {ratio, bytes}

      {:error, _} ->
        {-1.0, -1}
    end
  end

  defp meminfo_kb(text, label) do
    re = Regex.compile!(Regex.escape(label) <> ~S/\s+(\d+)\s+kB/)

    case Regex.run(re, text) do
      [_, kb] -> String.to_integer(kb)
      _ -> -1
    end
  end

  defp gpu_metrics(hw) do
    nvidia =
      if metal_cfg(:nvidia_smi, true) do
        try_nvidia_smi()
      else
        :miss
      end

    case nvidia do
      {:ok, triple} -> triple
      _ -> gpu_from_rice_hardware(hw)
    end
  end

  defp try_nvidia_smi do
    case System.find_executable("nvidia-smi") do
      nil ->
        :miss

      exe ->
        cmd =
          "#{exe} --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null"

        case System.cmd("sh", ["-c", cmd], stderr_to_stdout: true, timeout: metal_cfg(:nvidia_smi_timeout_ms, 2_000)) do
          {out, 0} ->
            line =
              case out |> String.trim() |> String.split("\n") |> List.first() do
                nil -> ""
                s when is_binary(s) -> s
                _ -> ""
              end

            case String.split(line, ", ") do
              [u, used, tot] ->
                with {:ok, uF} <- parse_float(u),
                     {:ok, usedF} <- parse_float(used),
                     {:ok, totF} <- parse_float(tot) do
                  {:ok, {uF, usedF, totF, true}}
                else
                  _ -> :miss
                end

              _ ->
                :miss
            end

          _ ->
            :miss
        end
    end
  end

  defp gpu_from_rice_hardware(hw) when is_map(hw) do
    util =
      deep_get(hw, ["gpu", "utilization_percent"]) ||
        deep_get(hw, ["gpu", "utilization"]) || deep_get(hw, ["gpu_utilization"]) || 0.0

    used = deep_get(hw, ["gpu", "memory_used_mib"]) || deep_get(hw, ["gpu", "mem_used_mib"]) || 0.0
    tot = deep_get(hw, ["gpu", "memory_total_mib"]) || deep_get(hw, ["gpu", "mem_total_mib"]) || 0.0
    ok = util > 0 or used > 0 or tot > 0
    {to_float(util), to_float(used), to_float(tot), ok}
  end

  defp sage_gpu_ready?(hw) do
    case deep_get(hw, ["sage", "gpu_ready"]) || deep_get(hw, ["sage", "gpuReady"]) do
      true -> true
      "true" -> true
      1 -> true
      _ -> false
    end
  end

  defp rice_hardware_map do
    path =
      metal_cfg(:rice_hardware_json_path, nil) ||
        Path.expand("~/.rice-hardware.json")

    case File.read(path) do
      {:ok, bin} ->
        case Jason.decode(bin) do
          {:ok, %{} = m} -> m
          _ -> %{}
        end

      {:error, _} ->
        %{}
    end
  end

  defp deep_get(map, keys) when is_map(map) and is_list(keys), do: do_deep_get(map, keys)

  defp deep_get(_, _), do: nil

  defp do_deep_get(nil, _), do: nil

  defp do_deep_get(map, []) when is_map(map), do: map

  defp do_deep_get(map, [key | rest]) when is_map(map) do
    v = Map.get(map, key) || Map.get(map, to_string(key))

    case v do
      nil ->
        nil

      inner when is_map(inner) ->
        do_deep_get(inner, rest)

      other ->
        if rest == [], do: other, else: nil
    end
  end

  defp do_deep_get(_, _), do: nil

  defp to_float(v) when is_float(v), do: v
  defp to_float(v) when is_integer(v), do: v * 1.0

  defp to_float(v) when is_binary(v) do
    case parse_float(v) do
      {:ok, x} -> x
      _ -> 0.0
    end
  end

  defp to_float(_), do: 0.0

  defp parse_float(s) when is_binary(s) do
    case Float.parse(String.trim(s)) do
      {x, _} -> {:ok, x}
      :error -> :error
    end
  end

  defp parse_float(_), do: :error

  defp clamp_percent(v) when is_number(v) do
    v |> max(0.0) |> min(100.0)
  end
end

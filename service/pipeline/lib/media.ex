defmodule Smith.Pipeline.Media do
  @moduledoc """
  Facade over Membrane **audio** vs **video** pipelines plus a tiny registry of active runs.

  State is stored in the named `Agent` `Smith.Pipeline.Media.State` (started by `Smith.Pipeline.Application`
  or tests that start it manually).
  """

  @type media_kind :: :audio | :video
  @type pipeline_id :: reference()

  @doc "Infer `:audio` or `:video` from MIME type or file extension."
  @spec detect_kind(keyword() | map()) :: media_kind()
  def detect_kind(opts) do
    opts = if(is_list(opts), do: Map.new(opts), else: opts)

    cond do
      mime = Map.get(opts, :mime_type) ->
        mime = String.downcase(mime)
        if(String.contains?(mime, "audio"), do: :audio, else: :video)

      path = Map.get(opts, :path) ->
        ext = path |> Path.extname() |> String.downcase()
        if(ext in [".wav", ".raw", ".pcm", ".mp3", ".aac", ".flac"], do: :audio, else: :video)

      Map.has_key?(opts, :input_paths) ->
        :audio

      true ->
        :video
    end
  end

  @doc "Starts the appropriate Membrane pipeline under a dedicated supervisor."
  @spec start_pipeline(media_kind(), map() | keyword()) ::
          {:ok, pipeline_id(), pid(), pid()} | {:error, term()}
  def start_pipeline(kind, opts \\ %{}) do
    opts = if(is_list(opts), do: Map.new(opts), else: opts)
    mod = if(kind == :audio, do: Smith.Pipeline.Audio, else: Smith.Pipeline.Video)
    id = Map.get(opts, :id, make_ref())

    case Membrane.Pipeline.start_link(mod, opts) do
      {:ok, sup, pid} ->
        record = %{kind: kind, supervisor: sup, pipeline: pid, started_at: System.system_time(:second)}
        _ = update_state(&Map.put(&1, id, record))
        {:ok, id, sup, pid}

      err ->
        err
    end
  end

  @doc "Starts pipeline using `detect_kind/1` on `opts`."
  @spec start_for_input(map() | keyword()) :: {:ok, pipeline_id(), pid(), pid()} | {:error, term()}
  def start_for_input(opts), do: start_pipeline(detect_kind(opts), opts)

  @doc "Returns all active pipeline records (best-effort; stale if processes died without unregister)."
  @spec active_pipelines() :: %{optional(pipeline_id()) => map()}
  def active_pipelines do
    get_state()
  end

  @doc "Removes a pipeline id from the registry (call on normal shutdown if desired)."
  @spec unregister(pipeline_id()) :: :ok
  def unregister(id) do
    case update_state(&Map.delete(&1, id)) do
      :ok -> :ok
      {:error, :no_media_agent} -> :ok
    end
  end

  defp get_state do
    case Process.whereis(Smith.Pipeline.Media.State) do
      nil -> %{}
      pid -> Agent.get(pid, & &1)
    end
  end

  defp update_state(fun) do
    case Process.whereis(Smith.Pipeline.Media.State) do
      nil -> {:error, :no_media_agent}
      pid -> Agent.update(pid, fun)
    end
  end
end

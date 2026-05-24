defmodule Smith.Pipeline.Audio do
  @moduledoc """
  Membrane pipeline: dual raw PCM inputs → `Membrane.AudioMixer` →
  `Membrane.FFmpeg.SWResample.Converter` → `Membrane.File.Sink`.

  Input files must be **raw s16le mono** at the mixer `stream_format` sample rate (default 16 kHz),
  because this graph does not include a container demuxer.
  """

  use Membrane.Pipeline

  @default_format %Membrane.RawAudio{
    channels: 1,
    sample_rate: 16_000,
    sample_format: :s16le
  }

  @impl true
  def handle_init(_ctx, opts) do
    opts = if(is_list(opts), do: Map.new(opts), else: opts)

    {left, right} = input_paths(opts)
    out = Map.fetch!(opts, :output_path)
    mix_format = Map.get(opts, :stream_format, @default_format)
    out_format =
      Map.get(opts, :output_stream_format, %Membrane.RawAudio{
        mix_format
        | channels: 2,
          sample_rate: 48_000
      })

    spec =
      [
        child(:src_left, %Membrane.File.Source{location: left})
        |> get_child(:mixer),

        child(:src_right, %Membrane.File.Source{location: right})
        |> via_in(:input,
          options: [offset: Membrane.Time.milliseconds(Map.get(opts, :right_offset_ms, 0))]
        )
        |> get_child(:mixer),

        child(:mixer, %Membrane.AudioMixer{
          stream_format: mix_format
        })
        |> child(:resample, %Membrane.FFmpeg.SWResample.Converter{
          input_stream_format: mix_format,
          output_stream_format: out_format
        })
        |> child(:sink, %Membrane.File.Sink{location: out})
      ]

    {[spec: spec], Map.put(opts, :formats, %{mix: mix_format, out: out_format})}
  end

  defp input_paths(%{input_paths: [a, b]}), do: {a, b}
  defp input_paths(%{input_paths: [a]}), do: {a, a}
  defp input_paths(%{input_left: a, input_right: b}), do: {a, b}

  defp input_paths(opts) do
    case {Map.get(opts, :input_path), Map.get(opts, :input_path_secondary)} do
      {a, b} when is_binary(a) and is_binary(b) -> {a, b}
      {a, _} when is_binary(a) -> {a, a}
      _ -> raise ArgumentError, "expected :input_paths, or :input_left/:input_right, or :input_path"
    end
  end
end

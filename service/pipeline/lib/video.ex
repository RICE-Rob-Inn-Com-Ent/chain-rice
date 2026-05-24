defmodule Smith.Pipeline.Video do
  @moduledoc """
  Membrane pipeline staging for **SAGE** downstream AI: copies/transfers a media file to a
  prepared location (byte-preserving) so heavier decode / frame servers can attach later.

  Extend this module with demuxers and decoders when matching plugins are added to `mix.exs`.
  """

  use Membrane.Pipeline

  @impl true
  def handle_init(_ctx, opts) do
    opts = if(is_list(opts), do: Map.new(opts), else: opts)
    input = Map.fetch!(opts, :input_path)
    output = Map.fetch!(opts, :output_path)

    spec = [
      child(:src, %Membrane.File.Source{location: input})
      |> child(:sink, %Membrane.File.Sink{location: output})
    ]

    {[spec: spec], opts}
  end
end

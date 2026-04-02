defmodule Service.Pipeline.Media do
  @moduledoc """
  Membrane pipeline shell — supervisor-style lifecycle for linked elements (playback, transcoding).

  Compose concrete graphs via `Service.Pipeline.Audio`, `Service.Pipeline.Video`, and
  `Service.Pipeline.Stream`; this module is the root `Membrane.Pipeline` entrypoint.
  """

  # TODO:
  # [ ] implement Membrane media router:
  #     routes media streams to audio.ex or video.ex by type
  #     media type detection from NATS message headers

  use Membrane.Pipeline

  @impl true
  def handle_init(_ctx, opts) do
    {[], Map.new(opts)}
  end
end

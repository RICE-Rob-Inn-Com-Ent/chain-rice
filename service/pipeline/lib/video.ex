defmodule Service.Pipeline.Video do
  @moduledoc """
  Video graph building blocks — source, decode, encode, sink. Add H264/H265 plugins when needed.

  Compose alongside `Service.Pipeline.Audio` under `Service.Pipeline.Media`.
  """

  # TODO:
  # [ ] implement Membrane video pipeline:
  #     reads video frames from NATS
  #     processes via Membrane plugins
  #     outputs to NATS or storage
  # [ ] implement video transcoding:
  #     codec config from RICE_PIPELINE_VIDEO_* env vars

  @spec element_children() :: []
  def element_children, do: []
end

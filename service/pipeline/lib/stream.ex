defmodule Service.Pipeline.Stream do
  @moduledoc """
  Live output paths — HLS, RTMP, WebRTC sinks and muxers (bring in Membrane plugins per target).

  Typically the terminal branch of `Service.Pipeline.Media` after encode/mix.
  """

  # TODO:
  # [ ] implement GenStage stream source:
  #     produces messages from NATS for Broadway
  #     back-pressure aware — respects demand
  # [ ] implement stream transformation:
  #     map, filter, reduce over message stream
  #     transformation config from RICE_PIPELINE_* env vars

  @spec sink_children() :: []
  def sink_children, do: []
end

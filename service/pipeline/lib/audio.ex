defmodule Service.Pipeline.Audio do
  @moduledoc """
  Audio graph building blocks — file/source, decode, resample, mix (see `membrane_audio_mix_plugin`,
  `membrane_ffmpeg_swresample_plugin` in `mix.exs`).

  Link elements from here inside `Service.Pipeline.Media.handle_init/2` or a dedicated bin.
  """

  # TODO:
  # [ ] implement Membrane audio pipeline:
  #     reads audio from NATS subject (BARD audio daemon)
  #     processes via membrane_audio_mix_plugin
  #     outputs to NATS output subject
  # [ ] implement audio format conversion:
  #     via membrane_ffmpeg_swresample_plugin
  #     input/output formats from RICE_PIPELINE_AUDIO_* env vars

  @doc "Placeholder for future element specs (bins, children maps)."
  @spec element_children() :: []
  def element_children, do: []
end

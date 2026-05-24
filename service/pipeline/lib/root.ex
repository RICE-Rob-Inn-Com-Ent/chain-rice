defmodule Smith.Pipeline.Root do
  @moduledoc """
  Public surface for the **`:pipeline`** app: NATS integration, Broadway pipelines, and media stages.

  Canonical modules:

    * `Smith.Pipeline.Application` — NATS, optional Broadway pipeline, media state
    * `Smith.Pipeline` — Broadway pipeline module (when enabled)
    * `Smith.Pipeline.Nats` — NATS bridge
    * `Smith.Pipeline.Producer`, `Smith.Pipeline.Consumer`, `Smith.Pipeline.Batcher`, `Smith.Pipeline.Processor`
    * `Smith.Pipeline.Stream`, `Smith.Pipeline.Media`, `Smith.Pipeline.Audio`, `Smith.Pipeline.Video`
  """
end

defmodule Service.Pipeline.Batcher do
  @moduledoc """
  Broadway batcher defaults: batch key (`:default`), flush by size and timeout, concurrency.
  """

  # TODO:
  # [ ] implement Broadway batcher config:
  #     batch_size from RICE_PIPELINE_BATCH_SIZE env var
  #     batch_timeout from RICE_PIPELINE_BATCH_TIMEOUT_MS env var
  # [ ] implement multiple batcher keys:
  #     route messages to different batchers by type
  #     batcher key from message metadata

  @spec batchers() :: keyword()
  def batchers do
    [
      default: [
        batch_size: 50,
        batch_timeout: 500,
        concurrency: 2
      ]
    ]
  end
end

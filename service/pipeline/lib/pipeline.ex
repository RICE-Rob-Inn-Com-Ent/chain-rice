defmodule Smith.Pipeline do
  @moduledoc """
  SMITH Broadway stack: NATS → processors → batchers → consumer (acks via `Smith.Pipeline.Nats`).

  Start **after** `Smith.Pipeline.Nats` in the supervision tree.
  """

  use Broadway

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    Broadway.start_link(__MODULE__, pipeline_opts(opts))
  end

  defp pipeline_opts(extra) do
    [
      name: __MODULE__,
      producer: [
        module: {Smith.Pipeline.Producer, []}
      ],
      processors: [
        default: [concurrency: 2]
      ],
      batchers: Smith.Pipeline.Batcher.batchers()
    ]
    |> Keyword.merge(extra)
  end

  @impl Broadway
  def handle_message(_processor, message, _context) do
    Smith.Pipeline.Processor.process(message)
  end

  @impl Broadway
  def handle_batch(:default, messages, _batch_info, _context) do
    Smith.Pipeline.Consumer.consume(messages)
  end

  @impl Broadway
  def handle_failed(messages, context) do
    Smith.Pipeline.Consumer.handle_failed(messages, context)
  end
end

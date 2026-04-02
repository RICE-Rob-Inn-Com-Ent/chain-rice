defmodule Service.Pipeline.Processor do
  @moduledoc """
  Per-message transform and enrichment (`handle_message` delegates here).
  """

  # TODO:
  # [ ] implement Broadway processor:
  #     process_message/3 — transforms single message
  #     deserializes proto payload from gen/
  #     applies business logic per message type
  # [ ] implement processor error handling:
  #     on error → message.failed() — NATS NAK with delay
  #     on success → message.ack() — NATS ACK

  alias Broadway.Message

  @spec process(Message.t()) :: Message.t()
  def process(%Message{data: data} = msg) when is_map(data) do
    Message.update_data(msg, &Map.put(&1, :processed_at, System.system_time(:millisecond)))
  end

  def process(%Message{} = msg), do: msg
end

defmodule Service.Pipeline do
  @moduledoc """
  SMITH Broadway pipeline: NATS → processors → batchers → consumer (ack via `Service.Pipeline.NATS`).

  Start after `Service.Pipeline.NATS` in the supervision tree. Example children:

      {Service.Pipeline.NATS, []},
      {Service.Pipeline, []}

  Topology is passed to `Broadway.start_link/2` (see `start_link/1`); `use Broadway` only wires the behaviour.
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
        module: {Service.Pipeline.Producer, []}
      ],
      processors: [
        default: [concurrency: 2]
      ],
      batchers: Service.Pipeline.Batcher.batchers()
    ]
    |> Keyword.merge(extra)
  end

  @impl Broadway
  def handle_message(_processor, message, _context) do
    Service.Pipeline.Processor.process(message)
  end

  @impl Broadway
  def handle_batch(:default, messages, _batch_info, _context) do
    Service.Pipeline.Consumer.consume(messages)
  end

  @impl Broadway
  def handle_failed(messages, context) do
    Service.Pipeline.Consumer.handle_failed(messages, context)
  end
end

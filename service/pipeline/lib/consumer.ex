defmodule Service.Pipeline.Consumer do
  @moduledoc """
  Final batch stage: business side-effects, success list for Broadway ack, failed routing.

  Invoked from `Service.Pipeline.handle_batch/4` and `handle_failed/2`.
  """

  # TODO:
  # [ ] implement Broadway batch consumer:
  #     handle_batch/4 — processes batch of messages
  #     batch size from RICE_PIPELINE_BATCH_SIZE env var
  #     batch timeout from RICE_PIPELINE_BATCH_TIMEOUT_MS env var
  # [ ] implement batch publishing:
  #     successful batch → publish results to NATS output subject
  #     failed batch → dead-letter subject

  alias Broadway.Message

  @spec consume([Message.t()]) :: [Message.t()]
  def consume(messages) do
    Enum.map(messages, &deliver/1)
  end

  defp deliver(%Message{} = m), do: m

  @spec handle_failed([Message.t()], term()) :: [Message.t()]
  def handle_failed(messages, _context) when is_list(messages) do
    # Route to DLQ / retry / logging — pass through for now.
    messages
  end
end

defmodule Smith.Pipeline.Consumer do
  @moduledoc """
  Terminal Broadway stage: publish successful batches to the configured output subject and
  surface failures to `handle_failed/2` (DLQ via `Smith.Pipeline.Nats.ack/3`).
  """

  alias Broadway.Message

  @spec consume([Message.t()]) :: [Message.t()]
  def consume(messages) do
    case output_subject() do
      subj when is_binary(subj) ->
        Enum.each(messages, fn m ->
          body = message_out_body(m)
          _ = Smith.Pipeline.Nats.pub(subj, body)
        end)

      _ ->
        :ok
    end

    messages
  end

  defp message_out_body(%Message{data: %{body: b}}) when is_binary(b), do: b

  defp message_out_body(%Message{data: data}) when is_map(data) do
    data |> Map.drop([:raw]) |> :erlang.term_to_binary()
  end

  defp message_out_body(_), do: ""

  defp output_subject do
    Application.get_env(:service, Smith.Pipeline, [])
    |> Keyword.get(:consumer, [])
    |> Keyword.get(:output_subject)
  end

  @spec handle_failed([Message.t()], term()) :: [Message.t()]
  def handle_failed(messages, _context) when is_list(messages) do
    messages
  end
end

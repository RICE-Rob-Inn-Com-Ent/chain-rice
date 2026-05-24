defmodule Smith.Pipeline.Processor do
  @moduledoc """
  Broadway processor: **lightweight** enrichment only — keep hot paths allocation-free for throughput.
  """

  alias Broadway.Message

  @spec process(Message.t()) :: Message.t()
  def process(%Message{data: data} = msg) when is_map(data) do
    Message.update_data(msg, fn d ->
      d
      |> Map.put(:processed_at, System.system_time(:millisecond))
      |> Map.put(:pipeline_node, Node.self())
    end)
  end

  def process(%Message{} = msg), do: msg
end

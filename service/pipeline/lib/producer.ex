defmodule Smith.Pipeline.Producer do
  @moduledoc """
  Broadway producer: subscribes to NATS via GNAT and emits `Broadway.Message` values with
  `Smith.Pipeline.Nats` as acknowledger (DLQ on failed batches).
  """

  use GenStage

  @behaviour Broadway.Producer

  @impl true
  def init(opts) do
    pipeline = Application.get_env(:service, Smith.Pipeline, [])
    producer_cfg = Keyword.merge(Keyword.get(pipeline, :producer, []), opts)

    conn = Keyword.fetch!(producer_cfg, :connection_name)
    topic = Keyword.fetch!(producer_cfg, :subscription_topic)

    sub_opts =
      producer_cfg
      |> Keyword.take([:queue_group])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)

    case Smith.Pipeline.Nats.sub(self(), topic, sub_opts) do
      {:ok, _sid} -> :ok
      {:error, reason} -> raise "Smith.Pipeline.Producer: NATS subscribe failed: #{inspect(reason)}"
    end

    {:producer, %{buffer: [], demand: 0, connection: conn}}
  end

  @impl true
  def handle_demand(incoming_demand, state) do
    state = %{state | demand: state.demand + incoming_demand}
    flush(state)
  end

  @impl true
  def handle_info({:msg, raw}, state) when is_map(raw) do
    topic = Map.get(raw, :topic)
    body = Map.get(raw, :body)
    reply_to = Map.get(raw, :reply_to)

    msg =
      %Broadway.Message{
        data: %{topic: topic, body: body, reply_to: reply_to, raw: raw},
        acknowledger: {Smith.Pipeline.Nats, raw, %{}}
      }

    flush(%{state | buffer: state.buffer ++ [msg]})
  end

  def handle_info(_, state), do: {:noreply, [], state}

  defp flush(%{demand: d} = state) when d <= 0, do: {:noreply, [], state}

  defp flush(%{demand: d, buffer: buf} = state) do
    case buf do
      [] ->
        {:noreply, [], state}

      _ ->
        {take, rest} = Enum.split(buf, d)
        n = length(take)
        {:noreply, take, %{state | buffer: rest, demand: d - n}}
    end
  end
end

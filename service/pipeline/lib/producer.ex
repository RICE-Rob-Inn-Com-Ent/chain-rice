defmodule Service.Pipeline.Producer do
  @moduledoc """
  Broadway `Broadway.Producer` — NATS subscription as GenStage source with demand-aware buffering.

  Subscribes in `c:init/1` using `connection_name` and `subscription_topic` from
  `Application.get_env(:service, Service.Pipeline)[:producer]`.

  Incoming NATS payloads are `{:msg, map}` (see GNAT `t:sent_message/0`).
  """

  # TODO:
  # [ ] implement Broadway producer via gnat:
  #     reads from NATS JetStream subject
  #     subject from RICE_PIPELINE_NATS_SUBJECT env var
  #     concurrency from RICE_PIPELINE_PRODUCER_CONCURRENCY env var
  # [ ] implement backpressure:
  #     demand-driven: only pull when downstream is ready
  #     max demand from RICE_PIPELINE_MAX_DEMAND env var

  use GenStage
  @behaviour Broadway.Producer

  @impl true
  def init(opts) do
    pipeline = Application.get_env(:service, Service.Pipeline, [])
    producer_cfg = Keyword.merge(Keyword.get(pipeline, :producer, []), opts)

    conn = Keyword.fetch!(producer_cfg, :connection_name)
    topic = Keyword.fetch!(producer_cfg, :subscription_topic)

    {:ok, _sid} = Gnat.sub(conn, self(), topic)

    {:producer, %{buffer: [], demand: 0}}
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
        acknowledger: {Service.Pipeline.NATS, raw, %{}}
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

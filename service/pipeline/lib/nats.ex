defmodule Service.Pipeline.NATS do
  @moduledoc """
  GNAT bridge: resilient connection via `Gnat.ConnectionSupervisor`, pub/sub hooks,
  and `Broadway.Acknowledger` for batch completion (extend for JetStream ack/nack).

  Configure under `config :service, Service.Pipeline.NATS` — see `config/config.exs`.
  """

  # TODO:
  # [ ] implement gnat NATS client for pipeline:
  #     connect to NATS_URL from env
  #     subscribe to pipeline input subjects
  #     publish to pipeline output subjects
  # [ ] implement JetStream consumer:
  #     durable consumer name from RICE_PIPELINE_CONSUMER env var
  #     ack wait from RICE_PIPELINE_ACK_WAIT_S env var

  @behaviour Broadway.Acknowledger

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts \\ []) do
    cfg = Application.get_env(:service, Service.Pipeline.NATS, [])
    merged = Map.merge(Map.new(cfg), Map.new(opts))

    %{
      id: __MODULE__,
      start: {Gnat.ConnectionSupervisor, :start_link, [merged]},
      type: :worker,
      restart: :permanent
    }
  end

  @impl Broadway.Acknowledger
  def ack(_ack_ref, _successful, _failed) do
    # Core NATS: messages are auto-acknowledged unless slow consumers / JetStream manual ack.
    # Wire JetStream: use ack_ref (subscription / consumer metadata) with Gnat.js_ack/2 etc.
    :ok
  end
end

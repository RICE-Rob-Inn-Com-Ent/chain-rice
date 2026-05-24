defmodule Smith.Pipeline.Nats do
  @moduledoc """
  GNAT-backed NATS access: supervised connection (`Gnat.ConnectionSupervisor`), pub/sub, and
  **request–reply** via `request/3` for KING mesh RPC.

  Configure under `config :service, Smith.Pipeline.Nats` (see `config/config.exs`).
  """

  @behaviour Broadway.Acknowledger

  @spec settings() :: map()
  def settings do
    env = Application.get_env(:service, Smith.Pipeline.Nats, []) |> List.wrap()

    defaults = [
      name: :smith_pipeline_nats,
      connection_settings: [%{host: "127.0.0.1", port: 4222}],
      backoff_period: 2_000
    ]

    Map.new(Keyword.merge(defaults, env))
  end

  @spec connection_name() :: atom()
  def connection_name do
    Map.get(settings(), :name, :smith_pipeline_nats)
  end

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts \\ []) do
    merged = Map.merge(settings(), Map.new(List.wrap(opts)))

    %{
      id: __MODULE__,
      start: {Gnat.ConnectionSupervisor, :start_link, [merged, []]},
      type: :supervisor,
      restart: :permanent
    }
  end

  @doc "Publish a message on `topic` using the configured connection name."
  @spec pub(String.t(), iodata(), keyword()) :: :ok | {:error, term()}
  def pub(topic, message, opts \\ []) do
    body = IO.iodata_to_binary(message)

    case Gnat.pub(connection_name(), topic, body, opts) do
      :ok ->
        :telemetry.execute([:smith, :nats, :published], %{count: 1}, %{topic: topic})
        :ok

      err ->
        err
    end
  rescue
    e -> {:error, {:smith_pipeline_nats, :pub, e}}
  end

  @doc "Subscribe `subscriber` pid to `topic` (queue group optional)."
  @spec sub(pid(), String.t(), keyword()) :: {:ok, non_neg_integer() | String.t()} | {:error, term()}
  def sub(subscriber, topic, opts \\ []) when is_pid(subscriber) do
    Gnat.sub(connection_name(), subscriber, topic, opts)
  rescue
    e -> {:error, {:smith_pipeline_nats, :sub, e}}
  end

  @doc """
  NATS core request–reply: blocks until a single response or timeout.

  Options are passed to `Gnat.request/4` (e.g. `receive_timeout`, `headers`).
  """
  @spec request(String.t(), binary(), keyword()) ::
          {:ok, map()} | {:error, :timeout | :no_responders | term()}
  def request(topic, body, opts \\ []) when is_binary(body) do
    Gnat.request(connection_name(), topic, body, request_opts(opts))
  rescue
    e -> {:error, {:smith_pipeline_nats, :request, e}}
  end

  defp request_opts(opts) do
    defaults =
      Application.get_env(:service, Smith.Pipeline.Nats, [])
      |> List.wrap()
      |> Keyword.get(:request_defaults, [])

    Keyword.merge(defaults, opts)
  end

  @impl Broadway.Acknowledger
  def ack(_gnat_raw, _successful, failed) do
    cfg = Application.get_env(:service, Smith.Pipeline, []) |> Keyword.get(:consumer, [])
    dlq = Keyword.get(cfg, :dead_letter_subject)

    if dlq && is_binary(dlq) do
      conn = connection_name()

      Enum.each(failed, fn
        %Broadway.Message{data: %{body: body}} when is_binary(body) ->
          _ = Gnat.pub(conn, dlq, body)

        %Broadway.Message{data: data} when is_map(data) ->
          body = Map.get(data, :body, "") |> to_body_binary()
          _ = Gnat.pub(conn, dlq, body)

        _ ->
          :ok
      end)
    end

    :ok
  end

  defp to_body_binary(b) when is_binary(b), do: b
  defp to_body_binary(other), do: inspect(other)
end

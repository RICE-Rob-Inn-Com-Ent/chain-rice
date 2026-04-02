defmodule Service.Connection.Http do
  @moduledoc """
  Finch HTTP facade: request building, pool selection, timeouts, TLS `transport_opts`.

  Uses `Service.Finch` from the guard connection stack unless overridden.
  """

  # TODO:
  # [ ] implement HTTP request building:
  #     build_request(method, url, headers, body) — Finch.Request
  #     injects OTel trace context into headers
  # [ ] implement response handling:
  #     parse_response(response) — maps status to RiceError
  #     200 → ok, 4xx → client error, 5xx → server error
  # [ ] implement retry logic:
  #     retry on 5xx: max RICE_CONNECTION_RETRIES env var
  #     exponential backoff: base from RICE_CONNECTION_BACKOFF_MS

  @type method :: Finch.Request.method()
  @type headers :: [{String.t(), String.t()}]

  @spec finch() :: module()
  def finch do
    Application.get_env(:service, Service.Connection, [])
    |> Keyword.get(:finch, Service.Finch)
  end

  @spec default_receive_timeout() :: non_neg_integer()
  def default_receive_timeout do
    Application.get_env(:service, Service.Connection, [])
    |> Keyword.get(:default_receive_timeout, 15_000)
  end

  @doc "Build a `Finch.Request` (method, absolute URL, headers, body, mint options)."
  @spec build(method(), String.t(), headers(), iodata() | nil, keyword()) :: Finch.Request.t()
  def build(method, url, headers \\ [], body \\ nil, opts \\ []) do
    Finch.build(method, url, headers, body, opts)
  end

  @doc """
  Execute request against Finch.

  Options: `:finch` (pool name), `:pool_timeout`, `:receive_timeout` (defaults from connection config),
  `:transport_opts` forwarded to Mint via `Finch.build/5` when building elsewhere — prefer passing them to `build/5`.
  """
  @spec request(Finch.Request.t(), keyword()) ::
          {:ok, Finch.Response.t()} | {:error, Mint.Types.error() | Finch.Error.t()}
  def request(%Finch.Request{} = req, opts \\ []) do
    finch_name = Keyword.get(opts, :finch, finch())
    timeout = Keyword.get(opts, :receive_timeout, default_receive_timeout())

    Finch.request(req, finch_name,
      pool_timeout: Keyword.get(opts, :pool_timeout, 5_000),
      receive_timeout: timeout
    )
  end

  @doc "One-shot: build + request."
  @spec run(method(), String.t(), keyword()) :: {:ok, Finch.Response.t()} | {:error, term()}
  def run(method, url, opts \\ []) do
    headers = Keyword.get(opts, :headers, [])
    body = Keyword.get(opts, :body)
    build_opts = Keyword.get(opts, :build_opts, [])

    req = build(method, url, headers, body, build_opts)
    request(req, opts)
  end
end

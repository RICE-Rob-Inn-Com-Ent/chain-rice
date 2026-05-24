defmodule Smith.Messages.Http do
  @moduledoc """
  Finch-backed HTTP facade for the `:messages` app.

  Pool name and timeouts come from `config :messages, Smith.Messages.Http, ...`.
  """

  @type method :: Finch.Request.method()
  @type headers :: [{String.t(), String.t()}]

  @spec finch() :: module()
  def finch do
    Application.get_env(:messages, Smith.Messages.Http, [])
    |> Keyword.get(:finch, Smith.Messages.Finch)
  end

  @spec default_receive_timeout() :: pos_integer()
  def default_receive_timeout do
    Application.get_env(:messages, Smith.Messages.Http, [])
    |> Keyword.get(:default_receive_timeout, 15_000)
  end

  @spec default_pool_timeout() :: pos_integer()
  def default_pool_timeout do
    Application.get_env(:messages, Smith.Messages.Http, [])
    |> Keyword.get(:pool_timeout, 5_000)
  end

  @doc """
  Runs a single HTTP request on the configured Finch pool.

  Options: `:finch`, `:pool_timeout`, `:receive_timeout`, `:build_opts` (passed to `Finch.build/5`).
  """
  @spec request(method(), String.t(), headers(), iodata() | nil, keyword()) ::
          {:ok, Finch.Response.t()} | {:error, term()}
  def request(method, url, headers \\ [], body \\ nil, opts \\ []) do
    build_opts = Keyword.get(opts, :build_opts, [])
    req = Finch.build(method, url, headers, body, build_opts)
    finch_name = Keyword.get(opts, :finch, finch())
    pool_timeout = Keyword.get(opts, :pool_timeout, default_pool_timeout())
    receive_timeout = Keyword.get(opts, :receive_timeout, default_receive_timeout())

    case Finch.request(req, finch_name,
           pool_timeout: pool_timeout,
           receive_timeout: receive_timeout
         ) do
      {:ok, _} = ok ->
        ok

      {:error, reason} ->
        {:error, {:smith_messages, :http, reason}}
    end
  end
end

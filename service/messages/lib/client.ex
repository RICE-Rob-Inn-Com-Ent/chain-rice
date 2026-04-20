defmodule Service.Connection.Client do
  @moduledoc """
  Role-scoped HTTP calls: resolves `base_url` from `config :service, Service.Connection, :roles`
  and runs `Finch` via `Service.Connection.Http` with optional `Service.Connection.Retry`.
  """

  # TODO:
  # [ ] implement HTTP client via Finch:
  #     start_link/1 — starts Finch pool
  #     pool size from RICE_CONNECTION_POOL_SIZE env var
  #     timeout from RICE_CONNECTION_TIMEOUT_MS env var
  # [ ] implement inter-role HTTP calls:
  #     get(url, headers) — GET with OTel span
  #     post(url, body, headers) — POST with OTel span
  #     all URLs from env vars — never hardcoded

  @type role :: :smith | :sage | :bard | :clerk | :king | :chief | :mason

  @spec roles() :: [role()]
  def roles do
    Application.get_env(:service, Service.Connection, [])
    |> Keyword.get(:roles, %{})
    |> Map.keys()
  end

  @doc """
  `path` is relative (e.g. `"/health"`). Body is iodata or nil.

  Options: `:headers`, `:receive_timeout`, `:finch`, `:build_opts` (Mint/Finch), `:retry` (keyword or `false` to disable).
  """
  @spec request(role(), Service.Connection.Http.method(), String.t(), iodata() | nil, keyword()) ::
          {:ok, Finch.Response.t()} | {:error, term()}
  def request(role, method, path, body \\ nil, opts \\ []) do
    url = join_url(base_url!(role), path)
    headers = build_headers(method, body, opts)
    build_opts = Keyword.get(opts, :build_opts, [])

    req = Service.Connection.Http.build(method, url, headers, body, build_opts)
    http_opts = Keyword.drop(opts, [:headers, :build_opts, :retry, :content_type])

    run =
      fn ->
        Service.Connection.Http.request(req, http_opts)
      end

    case Keyword.get(opts, :retry, []) do
      false -> run.()
      [] -> run.()
      retry_opts -> Service.Connection.Retry.with_retry(run, retry_opts)
    end
  end

  defp base_url!(role) do
    roles = Application.get_env(:service, Service.Connection, [])[:roles] || %{}

    case Map.fetch(roles, role) do
      {:ok, conf} -> Keyword.fetch!(conf, :base_url)
      :error -> raise ArgumentError, "unknown Service.Connection role #{inspect(role)}"
    end
  end

  defp join_url(base, path) do
    base = String.trim_trailing(base, "/")
    path = if String.starts_with?(path, "/"), do: path, else: "/" <> path
    base <> path
  end

  defp build_headers(method, body, opts) when method in [:post, :put, :patch] and not (body in [nil, ""]) do
    extra = Keyword.get(opts, :headers, [])
    ct = Keyword.get(opts, :content_type, "application/json")

    merge_headers(
      [{"accept", "application/json"}, {"content-type", header_value(ct)}],
      extra
    )
  end

  defp build_headers(_method, _body, opts) do
    merge_headers([{"accept", "application/json"}], Keyword.get(opts, :headers, []))
  end

  defp header_value(ct) when is_binary(ct), do: ct
  defp header_value(ct) when is_atom(ct), do: Atom.to_string(ct)

  defp merge_headers(base, extra) when is_list(extra) do
    Enum.uniq_by(base ++ extra, fn {k, _} -> String.downcase(to_string(k)) end)
  end
end

defmodule Service.Connection.Client.Smith do
  @moduledoc "Typed client for SMITH role backends."
  def request(m, p, b \\ nil, o \\ []), do: Service.Connection.Client.request(:smith, m, p, b, o)
  def get(p, o \\ []), do: request(:get, p, nil, o)
  def post(p, b, o \\ []), do: request(:post, p, b, o)
  def put(p, b, o \\ []), do: request(:put, p, b, o)
  def delete(p, o \\ []), do: request(:delete, p, nil, o)
end

defmodule Service.Connection.Client.Sage do
  @moduledoc "Typed client for SAGE role backends."
  def request(m, p, b \\ nil, o \\ []), do: Service.Connection.Client.request(:sage, m, p, b, o)
  def get(p, o \\ []), do: request(:get, p, nil, o)
  def post(p, b, o \\ []), do: request(:post, p, b, o)
end

defmodule Service.Connection.Client.Bard do
  @moduledoc "Typed client for BARD role backends."
  def request(m, p, b \\ nil, o \\ []), do: Service.Connection.Client.request(:bard, m, p, b, o)
  def get(p, o \\ []), do: request(:get, p, nil, o)
  def post(p, b, o \\ []), do: request(:post, p, b, o)
end

defmodule Service.Connection.Client.Clerk do
  @moduledoc "Typed client for CLERK role backends."
  def request(m, p, b \\ nil, o \\ []), do: Service.Connection.Client.request(:clerk, m, p, b, o)
  def get(p, o \\ []), do: request(:get, p, nil, o)
  def post(p, b, o \\ []), do: request(:post, p, b, o)
end

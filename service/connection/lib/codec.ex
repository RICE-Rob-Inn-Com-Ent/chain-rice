defmodule Service.Connection.Codec do
  @moduledoc """
  Unified encode/decode: JSON (Jason) or protobuf (generated modules) based on format or `Accept`/`Content-Type`.
  """

  # TODO:
  # [ ] implement unified codec:
  #     encode(term, :json | :proto) → binary
  #     decode(binary, :json | :proto, module) → term
  #     format from RICE_CONNECTION_CODEC env var (default: proto)

  @type format :: :json | :protobuf

  @spec decode(String.t(), format(), keyword()) :: {:ok, term()} | {:error, term()}
  def decode(body, :json, opts \\ []) do
    Service.Connection.Json.decode(body, opts)
  end

  def decode(body, :protobuf, opts) when is_binary(body) do
    mod = Keyword.fetch!(opts, :module)
    {:ok, Service.Connection.Proto.decode(mod, body)}
  rescue
    e -> {:error, e}
  end

  @spec decode!(String.t(), format(), keyword()) :: term()
  def decode!(body, :json, opts \\ []) do
    Service.Connection.Json.decode!(body, opts)
  end

  def decode!(body, :protobuf, opts) when is_binary(body) do
    mod = Keyword.fetch!(opts, :module)
    Service.Connection.Proto.decode(mod, body)
  end

  @spec encode(term(), format(), keyword()) :: {:ok, iodata()} | {:error, term()}
  def encode(term, :json, opts \\ []) do
    Service.Connection.Json.encode(term, opts)
  end

  def encode(%_{} = msg, :protobuf, _opts) do
    {:ok, Service.Connection.Proto.encode(msg)}
  rescue
    e -> {:error, e}
  end

  @doc "Infer wire format from an HTTP `accept` or `content-type` header value."
  @spec format_from_header(String.t() | nil) :: format()
  def format_from_header(nil), do: :json

  def format_from_header(header) when is_binary(header) do
    h = String.downcase(header)

    cond do
      String.contains?(h, "protobuf") or String.contains?(h, "x-protobuf") -> :protobuf
      true -> :json
    end
  end
end

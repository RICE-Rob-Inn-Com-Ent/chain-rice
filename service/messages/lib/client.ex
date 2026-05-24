defmodule Smith.Messages.Client do
  @moduledoc """
  KING-oriented HTTP client: Finch transport (`Smith.Messages.Http`), codec selection from
  `Content-Type`, and `Smith.Messages.Retry` on every outbound call.

  Request encoding uses the **request** `Content-Type` when present; otherwise it infers
  JSON vs protobuf from the body shape (struct → protobuf).

  Response decoding uses the **response** `Content-Type`. For protobuf responses you must
  pass `proto_message: :MyMessageName` (registered under `Smith.Messages.Proto`).
  """

  @type response_map :: %{response: Finch.Response.t(), decoded: term() | nil}

  @doc """
  Performs an HTTP request with retries, then decodes the body when possible.

  Options:
  - `:retry` — `keyword()` passed to `Smith.Messages.Retry.with_retry/2`, or `false` to disable
  - `:request_format` — force `:json` | `:protobuf` when there is no `content-type` header
  - `:proto_message` — atom name of the protobuf message for **response** decoding
  - `:json_decode_type` — `:default`, `:atoms`, or `:atoms!` for `Smith.Messages.Json.decode/2`
  - `:content_type` — override default `content-type` value inserted when absent
  - other options forwarded to `Smith.Messages.Http.request/5` (`:finch`, `:receive_timeout`, `:build_opts`, …)
  """
  @spec request(Smith.Messages.Http.method(), String.t(), Smith.Messages.Http.headers(), term(), keyword()) ::
          {:ok, response_map()} | {:error, term()}
  def request(method, url, headers \\ [], body \\ nil, opts \\ []) do
    headers = normalize_headers(headers)

    with {:ok, wire} <- request_wire_format(headers, body, opts),
         {:ok, body_out, headers_out} <- encode_request_body(body, headers, wire, opts) do
      http_opts = Keyword.drop(opts, [:retry, :request_format, :proto_message, :json_decode_type, :content_type])

      http_fun = fn ->
        Smith.Messages.Http.request(method, url, headers_out, body_out, http_opts)
      end

      case run_retry(http_fun, Keyword.get(opts, :retry, [])) do
        {:ok, %Finch.Response{} = resp} -> decode_success(resp, opts)
        {:error, _} = err -> err
      end
    end
  end

  defp run_retry(fun, false), do: fun.()

  defp run_retry(fun, retry_opts) when is_list(retry_opts) do
    Smith.Messages.Retry.with_retry(fun, retry_opts)
  end

  defp decode_success(%Finch.Response{body: body} = resp, opts) when body in [nil, ""] do
    {:ok, %{response: resp, decoded: nil}}
  end

  defp decode_success(%Finch.Response{body: body, headers: rh} = resp, opts) when is_binary(body) do
    case header_value(rh, "content-type") |> classify_content_type() do
      :json ->
        json_type = Keyword.get(opts, :json_decode_type, :default)

        case Smith.Messages.Json.decode(body, json_type) do
          {:ok, data} -> {:ok, %{response: resp, decoded: data}}
          {:error, _} = err -> err
        end

      :protobuf ->
        case Keyword.fetch(opts, :proto_message) do
          {:ok, msg_name} ->
            case Smith.Messages.Proto.decode(body, msg_name) do
              {:ok, data} -> {:ok, %{response: resp, decoded: data}}
              {:error, _} = err -> err
            end

          :error ->
            {:error, {:smith_messages, :client, :proto_message_required_for_protobuf_response}}
        end

      :unknown ->
        {:ok, %{response: resp, decoded: body}}
    end
  end

  defp normalize_headers(headers) when is_list(headers) do
    Enum.map(headers, fn {k, v} ->
      {to_string(k), to_string(v)}
    end)
  end

  defp header_value(headers, name) do
    n = String.downcase(name)

    Enum.find_value(headers, fn {k, v} ->
      if String.downcase(to_string(k)) == n, do: v
    end)
  end

  defp request_wire_format(headers, body, opts) do
    cond do
      v = header_value(headers, "content-type") ->
        {:ok, classify_content_type(v)}

      f = Keyword.get(opts, :request_format) ->
        {:ok, f}

      true ->
        {:ok, infer_wire_from_body(body)}
    end
  end

  defp infer_wire_from_body(%_{}), do: :protobuf
  defp infer_wire_from_body(_), do: :json

  defp classify_content_type(nil), do: :unknown

  defp classify_content_type(ct) when is_binary(ct) do
    h = String.downcase(ct)

    cond do
      String.contains?(h, "json") -> :json
      String.contains?(h, "protobuf") or String.contains?(h, "x-protobuf") -> :protobuf
      true -> :unknown
    end
  end

  defp encode_request_body(nil, headers, _wire, _opts), do: {:ok, nil, headers}

  defp encode_request_body(body, headers, _wire, _opts) when is_binary(body),
    do: {:ok, body, headers}

  defp encode_request_body(body, headers, :json, opts) do
    case Smith.Messages.Json.encode(body) do
      {:ok, bin} ->
        headers_out = ensure_header(headers, "content-type", "application/json", opts)
        {:ok, bin, headers_out}

      {:error, _} = err ->
        err
    end
  end

  defp encode_request_body(%_{} = body, headers, :protobuf, opts) do
    case Smith.Messages.Proto.encode(body) do
      {:ok, bin} ->
        headers_out = ensure_header(headers, "content-type", "application/x-protobuf", opts)
        {:ok, bin, headers_out}

      {:error, _} = err ->
        err
    end
  end

  defp encode_request_body(_body, _headers, :protobuf, _opts),
    do: {:error, {:smith_messages, :client, :protobuf_request_body_must_be_struct}}

  defp encode_request_body(body, headers, :unknown, opts) when is_binary(body),
    do: {:ok, body, headers}

  defp encode_request_body(body, headers, :unknown, opts) do
    encode_request_body(body, headers, infer_wire_from_body(body), opts)
  end

  defp ensure_header(headers, name, default_value, opts) do
    if header_value(headers, name) do
      headers
    else
      value = Keyword.get(opts, :content_type, default_value)
      [{name, value} | headers]
    end
  end
end

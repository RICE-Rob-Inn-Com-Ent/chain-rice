defmodule Smith.Core.Channel do
  @moduledoc """
  General-purpose `.rice` channel: commands from the UI (BARD) → **Smith.Core.Server** → Pipeline / PubSub.

  Incoming payloads are normalized via **`Smith.Messages.Codec`** (default `Smith.Messages.Json`).
  """

  use Phoenix.Channel

  alias Smith.Core.Presence

  @impl true
  def join("rice:bridge:" <> scope, params, socket) do
    session_id = socket.assigns.session_id

    meta = %{
      scope: scope,
      interface: socket.assigns.interface,
      resources: List.wrap(params["resources"] || params[:resources]),
      project: params["project"] || params[:project],
      role: params["role"] || params[:role]
    }

    socket = assign(socket, :scope, scope)

    case Presence.track(socket, session_id, meta) do
      {:ok, _} ->
        Smith.Core.Server.notify_join(scope, meta)
        {:ok, socket}

      {:error, reason} ->
        {:error, %{reason: inspect(reason)}}
    end
  end

  @impl true
  def handle_in(event, payload, socket) when is_map(payload) do
    codec = channel_codec()
    decode_type = decode_type_from_payload(payload)

    with {:ok, bin} <- payload_to_binary(payload),
         {:ok, data} <- codec.decode(bin, decode_type) do
      envelope = %{
        "event" => event,
        "scope" => socket.assigns.scope,
        "data" => data
      }

      Smith.Core.Server.ingest(envelope)
      {:reply, {:ok, %{echo: "accepted"}}, socket}
    else
      {:error, reason} ->
        {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  defp channel_codec do
    Application.get_env(:service, Smith.Core.Channel, [])
    |> Keyword.get(:codec, Smith.Messages.Json)
  end

  defp decode_type_from_payload(payload) do
    case Map.get(payload, "keys") || Map.get(payload, :keys) do
      "atoms" -> :atoms
      "atoms!" -> :atoms!
      _ -> []
    end
  end

  defp payload_to_binary(%{"body" => body}) when is_binary(body), do: {:ok, body}

  defp payload_to_binary(%{"body" => body}) when is_map(body) do
    Smith.Messages.Json.encode(body)
  end

  defp payload_to_binary(%{body: body}) when is_binary(body), do: {:ok, body}

  defp payload_to_binary(%{body: body}) when is_map(body) do
    Smith.Messages.Json.encode(body)
  end

  defp payload_to_binary(payload) when is_map(payload) do
    Smith.Messages.Json.encode(payload)
  end
end

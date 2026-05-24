defmodule Smith.Core.Socket do
  @moduledoc """
  WebSocket entry for **Phoenix Channels** (BARD ↔ microservices).

  Optional token in `connect` (`params["token"]`) — kept for a future PASETO integration.
  """

  use Phoenix.Socket

  channel "rice:bridge:*", Smith.Core.Channel

  @impl true
  def connect(params, socket, _connect_info) do
    _ = params["token"]
    session_id = params["session_id"] || Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)

    socket =
      socket
      |> assign(:session_id, session_id)
      |> assign(:interface, params["interface"] || "bard")

    {:ok, socket}
  end

  @impl true
  def id(socket), do: "smith_socket:#{socket.assigns.session_id}"
end

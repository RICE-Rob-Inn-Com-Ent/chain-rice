defmodule Smith.Core.Application do
  use Application

  # TODO:
  # [ ] implement Application.start/2:
  #     starts core supervision tree
  #     children: Endpoint, PubSub, Presence, Phoenix.Presence
  # [ ] implement Phoenix endpoint config:
  #     port from RICE_WEB_PORT env var
  #     secret_key_base from SOPS secret
  # [ ] implement graceful shutdown:
  #     on SIGTERM → drain WebSocket connections
  #     timeout from RICE_CORE_SHUTDOWN_TIMEOUT_S env var

  @impl true
  def start(_type, _args) do
    Supervisor.start_link([], strategy: :one_for_one, name: Smith.Core.Supervisor)
  end
end

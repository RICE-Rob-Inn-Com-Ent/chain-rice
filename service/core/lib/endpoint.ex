defmodule Smith.Core.Endpoint do
  @moduledoc """
  Phoenix **Endpoint** on **Bandit** (`Bandit.PhoenixAdapter`): HTTP, WebSocket (Channels + LiveView),
  telemetry for **Smith.Guard.Metrics**.
  """

  use Phoenix.Endpoint, otp_app: :service

  @session_options [
    store: :cookie,
    key: "_rice_smith_session",
    signing_salt: "rice_smith_signing_salt"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  socket "/socket", Smith.Core.Socket,
    websocket: true,
    longpoll: false

  plug Plug.Static,
    at: "/",
    from: :phoenix_live_dashboard,
    gzip: true,
    only: Phoenix.LiveDashboard.Router.static_paths()

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug Smith.Core.Router
end

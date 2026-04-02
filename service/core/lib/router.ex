defmodule Smith.Core.Router do
  # TODO:
  # [ ] implement Phoenix Router:
  #     pipeline :api — JSON content-type + PASETO auth
  #     pipeline :browser — session + CSRF
  # [ ] implement route scopes:
  #     scope "/api" → ConnectRPC proxy routes
  #     scope "/ws" → WebSocket upgrade
  #     scope "/health" → health check (no auth)
  # [ ] implement LiveDashboard mount:
  #     /dashboard → Phoenix LiveDashboard
  #     protected by RICE_DASHBOARD_PASSWORD env var
  #     dev only: RICE_ENV=dev check
end

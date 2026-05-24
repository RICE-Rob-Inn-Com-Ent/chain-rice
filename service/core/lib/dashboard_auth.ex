defmodule Smith.Core.DashboardAuth do
  @moduledoc """
  Basic auth for **Phoenix.LiveDashboard** (`RICE_DASHBOARD_USER` / `RICE_DASHBOARD_PASSWORD`).
  In `:dev` with no password configured, access is open only for local development.
  """

  import Plug.Conn

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    pass = System.get_env("RICE_DASHBOARD_PASSWORD")

    cond do
      dashboard_open_dev?(pass) ->
        conn

      pass in [nil, ""] ->
        conn
        |> send_resp(503, "LiveDashboard disabled: set RICE_DASHBOARD_PASSWORD")
        |> halt()

      true ->
        user = System.get_env("RICE_DASHBOARD_USER", "rice")
        Plug.BasicAuth.basic_auth(conn, username: user, password: pass)
    end
  end

  defp dashboard_open_dev?(pass) do
    pass in [nil, ""] and
      Keyword.get(Application.get_env(:service, Smith.Core, []), :dashboard_dev_open, false)
  end
end

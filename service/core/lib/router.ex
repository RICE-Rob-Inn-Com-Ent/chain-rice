defmodule Smith.Core.Router do
  @moduledoc """
  SMITH routes: **:api** (JSON), protected **LiveDashboard** (Guard metrics).
  """

  use Phoenix.Router
  import Phoenix.LiveView.Router
  import Phoenix.LiveDashboard.Router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :dashboard do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Smith.Core.Layouts, :root}
    plug :put_secure_browser_headers
    plug Smith.Core.DashboardAuth
  end

  scope "/api", Smith.Core do
    pipe_through :api
    get "/health", HealthController, :index
  end

  scope "/" do
    pipe_through :dashboard
    live_dashboard "/dashboard", metrics: Smith.Guard.Metrics
  end
end

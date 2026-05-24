defmodule Smith.Core.HealthController do
  use Phoenix.Controller

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    json(conn, %{status: "ok", core: Smith.Core.Server.summary()})
  end
end

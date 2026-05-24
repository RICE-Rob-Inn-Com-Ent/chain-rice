defmodule Smith.Connection.Application do
  @moduledoc """
  OTP entry for `:connection`: thin supervisor root (cluster processes are started by `Smith.Guard.Supervisor`
  via `Smith.Connection.Topology.children/0` when `Smith.Connection.Topology.enabled?/0`).
  """

  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link([], strategy: :one_for_one, name: Smith.Connection.SupervisorRoot)
  end
end

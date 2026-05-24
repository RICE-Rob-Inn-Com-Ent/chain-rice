defmodule Smith.Connection.Root do
  @moduledoc """
  Public surface for the **`:connection`** app: cluster topology, registries, and handoff between nodes.

  Canonical modules:

    * `Smith.Connection.Application` — OTP application entry
    * `Smith.Connection.Topology` — cluster strategy and children
    * `Smith.Connection.Supervisor`, `Smith.Connection.Registry`, `Smith.Connection.Strategy`
    * `Smith.Connection.Handoff`, `Smith.Connection.Observer`
  """
end

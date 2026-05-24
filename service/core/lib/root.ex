defmodule Smith.Core.Root do
  @moduledoc """
  Public surface for the **`:core`** OTP app: Phoenix endpoint, channels, presence, and runtime
  supervision after Guard readiness.

  Canonical modules (import or alias these directly):

    * `Smith.Core.Application` — OTP application entry
    * `Smith.Core.Readiness` — waits on Guard metrics before boot
    * `Smith.Core.Runtime` — supervision tree (PubSub, Presence, Server, Endpoint)
    * `Smith.Core.Endpoint`, `Smith.Core.Router`, `Smith.Core.Server`
    * `Smith.Core.PubSub`, `Smith.Core.Presence`, `Smith.Core.Channel`, `Smith.Core.Socket`
    * `Smith.Core.Layouts`, `Smith.Core.DashboardAuth`, `Smith.Core.HealthController`
  """
end

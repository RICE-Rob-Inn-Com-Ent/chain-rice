defmodule Smith.Core.Application do
  @moduledoc """
  OTP **`:core`**: once **Smith.Guard.Metrics** has been confirmed (`Smith.Core.Readiness`), starts
  **`Smith.Core.Runtime`** (PubSub, Presence, Server, Endpoint).
  """

  use Application

  @impl true
  def start(_type, _args) do
    Smith.Core.Readiness.await!()
    Smith.Core.Runtime.start_link()
  end
end

defmodule Service.Guard.Application do
  @moduledoc """
  OTP application entry — root is `Service.Guard.Supervisor` with effectively immortal restart policy.

  Replaces the legacy `Service.Application` callback; all runtime trees start under the Guard supervisor.
  """

  # TODO:
  # [ ] implement Application.start/2:
  #     start_permanent: true — GUARD NEVER STOPS
  #     children: Supervisor, Watcher, Metrics, Tracer, Alert
  # [ ] implement restart strategy:
  #     strategy: :one_for_one — independent child restarts
  #     max_restarts from RICE_GUARD_MAX_RESTARTS env var
  #     max_seconds from RICE_GUARD_MAX_SECONDS env var

  use Application

  @impl true
  def start(_type, _args) do
    Service.Guard.Supervisor.start_link(name: Service.Guard.Supervisor)
  end
end

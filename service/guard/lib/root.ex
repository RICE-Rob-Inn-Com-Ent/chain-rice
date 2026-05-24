defmodule Smith.Guard.Root do
  @moduledoc """
  Public surface for the **`:guard`** app: OpenTelemetry bootstrap, supervision, healing, and metal monitoring.

  Canonical modules:

    * `Smith.Guard.Application` — OTel ensure then `Smith.Guard.Supervisor`
    * `Smith.Guard.Supervisor` — root supervisor for metrics, watcher, healer, etc.
    * `Smith.Guard.Metrics`, `Smith.Guard.Telemetry`, `Smith.Guard.Tracer`
    * `Smith.Guard.Watcher`, `Smith.Guard.Healer`, `Smith.Guard.Metal`, `Smith.Guard.Alert`
  """
end

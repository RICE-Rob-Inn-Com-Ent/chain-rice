defmodule Smith.Guard.Application do
  @moduledoc """
  OTP entry for the **`:guard`** application: initialize **OpenTelemetry** (SDK + exporter), then
  `Smith.Guard.Supervisor` with its subtree (Metrics, Watcher, Healer, etc. — see `Smith.Guard.ObserveStack`).
  """

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    :ok = ensure_opentelemetry_started()
    Smith.Guard.Supervisor.start_link(name: Smith.Guard.Supervisor)
  end

  @doc false
  @spec ensure_opentelemetry_started() :: :ok
  def ensure_opentelemetry_started do
    # Order: SDK (`:opentelemetry`), then OTLP exporter — from `config :opentelemetry*`.
    _ = start_otel_app(:opentelemetry, "OpenTelemetry SDK")
    _ = start_otel_app(:opentelemetry_exporter, "OpenTelemetry exporter")
    :ok
  end

  defp start_otel_app(app, label) do
    case Application.ensure_all_started(app) do
      {:ok, _} ->
        :ok

      {:error, {_failed_app, reason}} ->
        Logger.warning("smith.guard: #{label} (#{app}) ensure_all_started: #{inspect(reason)}")
        :error

      {:error, reason} ->
        Logger.warning("smith.guard: #{label} (#{app}) ensure_all_started: #{inspect(reason)}")
        :error
    end
  end
end

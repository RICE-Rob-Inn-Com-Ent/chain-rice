defmodule Smith.Core.Readiness do
  @moduledoc """
  Wait for **Smith.Guard.Metrics** (and optionally the cluster) before accepting HTTP traffic.
  """

  @default_timeout_ms 60_000
  @poll_ms 100

  @doc "Blocks until `Smith.Guard.Metrics` is up and, when enabled, `Smith.Connection.Topology.nodes_status/0` succeeds."
  @spec await!(keyword()) :: :ok
  def await!(opts \\ []) do
    deadline = System.monotonic_time(:millisecond) + Keyword.get(opts, :timeout_ms, @default_timeout_ms)
    wait_metrics(deadline)
    wait_cluster_if_enabled(deadline)
    :ok
  end

  defp wait_metrics(deadline) do
    cond do
      Process.whereis(Smith.Guard.Metrics) != nil ->
        :ok

      System.monotonic_time(:millisecond) >= deadline ->
        raise "Smith.Core.Readiness: timeout waiting for Smith.Guard.Metrics"

      true ->
        Process.sleep(@poll_ms)
        wait_metrics(deadline)
    end
  end

  defp wait_cluster_if_enabled(_deadline) do
    if Smith.Connection.Topology.enabled?() do
      _ = Smith.Connection.Topology.nodes_status()
    end

    :ok
  end
end

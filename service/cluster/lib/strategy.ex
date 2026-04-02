defmodule Service.Cluster.Strategy do
  @moduledoc """
  Per-environment discovery strategies for libcluster topologies.

  Each function returns a keyword list suitable as the **value** of a topology entry, i.e.

      topologies: [
        prod: Service.Cluster.Strategy.kubernetes_dns(service: "...", application_name: "...")
      ]
  """

  # TODO:
  # [ ] implement custom cluster strategy if needed:
  #     topology polling interval from RICE_CLUSTER_POLL_S env var
  # [ ] implement node health:
  #     periodic ping between nodes
  #     dead node detection timeout from RICE_CLUSTER_DEAD_TIMEOUT_S

  @type topology_spec :: keyword()

  @spec kubernetes_dns(keyword()) :: topology_spec()
  def kubernetes_dns(opts \\ []) do
    [
      strategy: Cluster.Strategy.Kubernetes.DNS,
      config:
        Keyword.merge(
          [
            polling_interval: 5_000
          ],
          opts
        )
    ]
  end

  @spec kubernetes_api(keyword()) :: topology_spec()
  def kubernetes_api(opts \\ []) do
    [
      strategy: Cluster.Strategy.Kubernetes,
      config:
        Keyword.merge(
          [
            polling_interval: 5_000
          ],
          opts
        )
    ]
  end

  @spec gossip(keyword()) :: topology_spec()
  def gossip(opts \\ []) do
    [
      strategy: Cluster.Strategy.Gossip,
      config: opts
    ]
  end

  @spec epmd(keyword()) :: topology_spec()
  def epmd(opts \\ []) do
    [
      strategy: Cluster.Strategy.Epmd,
      config: opts
    ]
  end

  @spec dns_poll(keyword()) :: topology_spec()
  def dns_poll(opts \\ []) do
    [
      strategy: Cluster.Strategy.DNSPoll,
      config:
        Keyword.merge(
          [
            polling_interval: 5_000
          ],
          opts
        )
    ]
  end
end

defmodule Service.Cluster.Registry do
  @moduledoc """
  Horde `Horde.Registry` — cluster-wide names (`register/3`, `lookup/2`, `dispatch/4`) compatible with `Registry` API.

  For single-node dev, keep using `Service.ProcessRegistry`; switch `via/1` to this module when `Service.Cluster.Topology.enabled?/0`.
  """

  # TODO:
  # [ ] implement Horde.Registry for distributed process registry:
  #     register process by name across cluster
  #     lookup process by name — returns pid on any node
  # [ ] implement registry namespacing:
  #     names prefixed with RICE_ENV — never hardcoded
  # [ ] implement registry failure handling:
  #     on node down → Horde redistributes processes automatically

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts \\ []) do
    cfg = horde_cfg()

    defaults = [
      name: Keyword.get(opts, :name, cfg[:registry_name]),
      keys: :unique,
      members: :auto
    ]

    Horde.Registry.child_spec(Keyword.merge(defaults, opts))
  end

  @spec registry_name() :: atom()
  def registry_name do
    horde_cfg()[:registry_name] ||
      raise "missing :horde :registry_name in Service.Cluster config"
  end

  @doc "Via tuple for Horde.Registry (unique keys)."
  @spec via(term()) :: {:via, Horde.Registry, {atom(), term()}}
  def via(key), do: {:via, Horde.Registry, {registry_name(), key}}

  @doc "See `Horde.Registry.lookup/2`."
  @spec lookup(term()) :: [{pid(), term()}]
  def lookup(key), do: Horde.Registry.lookup(registry_name(), key)

  @doc "See `Horde.Registry.register/3`."
  @spec register(term(), term()) :: {:ok, pid()} | {:error, {:already_registered, pid()}}
  def register(key, value \\ nil), do: Horde.Registry.register(registry_name(), key, value)

  @doc "See `Horde.Registry.dispatch/4`."
  @spec dispatch(term(), term()) :: :ok
  def dispatch(key, mfa_or_fun), do: Horde.Registry.dispatch(registry_name(), key, mfa_or_fun)

  defp horde_cfg do
    Application.get_env(:service, Service.Cluster, [])
    |> Keyword.get(:horde, [])
  end
end

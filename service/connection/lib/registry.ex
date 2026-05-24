defmodule Smith.Connection.Registry do
  @moduledoc """
  Cluster-wide **`Horde.Registry`** — global names for Pipeline, Guard, and other SMITH services.

  Use `via/1` in `GenServer`, `lookup/1`, `register/2`, `dispatch/2` — like standard `Registry`,
  but keys are unique across the whole cluster.
  """

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
      raise ArgumentError, "missing :horde :registry_name in :service, Smith.Connection config"
  end

  @doc "Tuple `{:via, Horde.Registry, {name, key}}` for `GenServer.start_link(..., name: via(key))`."
  @spec via(term()) :: {:via, Horde.Registry, {atom(), term()}}
  def via(key), do: {:via, Horde.Registry, {registry_name(), key}}

  @spec lookup(term()) :: [{pid(), term()}]
  def lookup(key), do: Horde.Registry.lookup(registry_name(), key)

  @spec register(term(), term()) :: {:ok, pid()} | {:error, {:already_registered, pid()}}
  def register(key, value \\ nil), do: Horde.Registry.register(registry_name(), key, value)

  @spec dispatch(term(), term()) :: :ok
  def dispatch(key, mfa_or_fun), do: Horde.Registry.dispatch(registry_name(), key, mfa_or_fun)

  defp horde_cfg do
    Application.get_env(:service, Smith.Connection, [])
    |> Keyword.get(:horde, [])
  end
end

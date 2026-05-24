defmodule Smith.Core.Runtime do
  @moduledoc """
  Phoenix supervision tree: **PubSub** → **Presence** → **Server** → **Endpoint**.
  """

  use Supervisor

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, Keyword.merge([name: __MODULE__], opts))
  end

  @impl true
  def init(:ok) do
    children = [
      {Phoenix.PubSub, name: Smith.Core.PubSub.name(), adapter: Phoenix.PubSub.PG2},
      Smith.Core.Presence,
      Smith.Core.Server,
      Smith.Core.Endpoint
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

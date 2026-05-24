defmodule Smith.Core.PubSub do
  @moduledoc """
  Registered name for clustered **Phoenix.PubSub** (`Phoenix.PubSub.PG2`) in the SMITH cluster (aligned with `Smith.Connection`).

  Child under **`Smith.Core.Runtime`**: `{Phoenix.PubSub, name: Smith.Core.PubSub, adapter: Phoenix.PubSub.PG2}`.
  """

  @spec name() :: atom()
  def name do
    Application.get_env(:service, Smith.Core.PubSub, [])
    |> Keyword.get(:name, Smith.Core.PubSub)
  end
end

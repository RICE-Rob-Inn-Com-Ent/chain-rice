defmodule Smith.Messages.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    finch = Smith.Messages.Http.finch()
    pools = Application.get_env(:messages, :finch_pools, %{default: [size: 25, count: 1]})

    children = [
      {Finch, name: finch, pools: pools}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Smith.Messages.Supervisor)
  end
end

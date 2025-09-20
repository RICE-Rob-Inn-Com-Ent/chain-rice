defmodule ChainRice.Bridge.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start Finch for HTTP requests
      {Finch, name: ChainRiceFinch},
      
      # Start gRPC connection pool
      {ChainRice.Bridge.GrpcPool, []}
    ]

    opts = [strategy: :one_for_one, name: ChainRice.Bridge.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

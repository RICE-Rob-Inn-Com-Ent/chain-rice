defmodule Smith.Pipeline.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    broadway? =
      Application.get_env(:service, Smith.Pipeline.Application, [])
      |> Keyword.get(:start_broadway, true)

    children =
      [
        {Smith.Pipeline.Nats, []},
        %{
          id: Smith.Pipeline.Media.State,
          start: {Agent, :start_link, [fn -> %{} end, [name: Smith.Pipeline.Media.State]]},
          restart: :permanent
        }
      ] ++ if(broadway?, do: [{Smith.Pipeline, []}], else: [])

    Supervisor.start_link(children, strategy: :one_for_one, name: Smith.Pipeline.Supervisor)
  end
end

defmodule Smith.Pipeline.Batcher do
  @moduledoc """
  Broadway batcher defaults — size **10** or flush every **500 ms** (whichever hits first),
  overridable via `config :service, Smith.Pipeline, :batchers`.
  """

  @spec batchers() :: keyword()
  def batchers do
    Application.get_env(:service, Smith.Pipeline, [])
    |> Keyword.get(:batchers, default_batchers())
  end

  defp default_batchers do
    [
      default: [
        batch_size: 10,
        batch_timeout: 500,
        concurrency: 2
      ]
    ]
  end
end

defmodule ChainRice.Bridge.Config do
  @moduledoc """
  Configuration module for ChainRice Bridge.
  """

  @doc """
  Get ChainRice configuration.
  """
  def get do
    %{
      accounting_api_url: get_env(:accounting_api_url, "http://localhost:8080"),
      tax_api_url: get_env(:tax_api_url, "http://localhost:8081"),
      blockchain_url: get_env(:blockchain_url, "http://localhost:26657"),
      api_key: get_env(:api_key, ""),
      timeout: get_env(:timeout, 30_000)
    }
  end

  defp get_env(key, default) do
    Application.get_env(:chainrice_bridge, key, default)
  end
end

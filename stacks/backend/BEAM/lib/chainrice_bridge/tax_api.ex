defmodule ChainRice.Bridge.TaxApi do
  @moduledoc """
  Client for ChainRice Tax API operations.
  """

  alias ChainRice.Bridge.{Config, HttpClient}

  @doc """
  Create a new tax API client.
  """
  def new do
    %{config: Config.get()}
  end

  @doc """
  Calculate tax for given amount and tax type.
  """
  def calculate_tax(client, tax_data) do
    url = "#{client.config.tax_api_url}/api/v1/tax/calculate"
    
    case HttpClient.post(url, tax_data, headers(client)) do
      {:ok, response} -> {:ok, Jason.decode!(response.body)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get tax rates for different categories.
  """
  def get_tax_rates(client) do
    url = "#{client.config.tax_api_url}/api/v1/tax/rates"
    
    case HttpClient.get(url, headers(client)) do
      {:ok, response} -> {:ok, Jason.decode!(response.body)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Create a new contractor.
  """
  def create_contractor(client, contractor_data) do
    url = "#{client.config.tax_api_url}/api/v1/contractors"
    
    case HttpClient.post(url, contractor_data, headers(client)) do
      {:ok, response} -> {:ok, Jason.decode!(response.body)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get contractor by ID.
  """
  def get_contractor(client, contractor_id) do
    url = "#{client.config.tax_api_url}/api/v1/contractors/#{contractor_id}"
    
    case HttpClient.get(url, headers(client)) do
      {:ok, response} -> {:ok, Jason.decode!(response.body)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  List contractors with pagination.
  """
  def list_contractors(client, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    page_size = Keyword.get(opts, :page_size, 10)
    url = "#{client.config.tax_api_url}/api/v1/contractors?page=#{page}&pageSize=#{page_size}"
    
    case HttpClient.get(url, headers(client)) do
      {:ok, response} -> {:ok, Jason.decode!(response.body)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get calculation history.
  """
  def get_calculation_history(client, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    page_size = Keyword.get(opts, :page_size, 10)
    url = "#{client.config.tax_api_url}/api/v1/calculations/history?page=#{page}&pageSize=#{page_size}"
    
    case HttpClient.get(url, headers(client)) do
      {:ok, response} -> {:ok, Jason.decode!(response.body)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Health check for tax API.
  """
  def health_check do
    client = new()
    url = "#{client.config.tax_api_url}/health"
    
    case HttpClient.get(url, headers(client)) do
      {:ok, response} -> {:ok, response.status == 200}
      {:error, _reason} -> {:ok, false}
    end
  end

  defp headers(client) do
    base_headers = [
      {"content-type", "application/json"},
      {"accept", "application/json"}
    ]
    
    if client.config.api_key != "" do
      [{"authorization", "Bearer #{client.config.api_key}"} | base_headers]
    else
      base_headers
    end
  end
end

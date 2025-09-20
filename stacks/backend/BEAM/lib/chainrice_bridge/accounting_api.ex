defmodule ChainRice.Bridge.AccountingApi do
  @moduledoc """
  Client for ChainRice Accounting API operations.
  """

  alias ChainRice.Bridge.{Config, HttpClient}

  @doc """
  Create a new accounting API client.
  """
  def new do
    %{config: Config.get()}
  end

  @doc """
  Create a new invoice.
  """
  def create_invoice(client, invoice_data) do
    url = "#{client.config.accounting_api_url}/api/v1/invoices"
    
    case HttpClient.post(url, invoice_data, headers(client)) do
      {:ok, response} -> {:ok, Jason.decode!(response.body)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get invoice by ID.
  """
  def get_invoice(client, invoice_id) do
    url = "#{client.config.accounting_api_url}/api/v1/invoices/#{invoice_id}"
    
    case HttpClient.get(url, headers(client)) do
      {:ok, response} -> {:ok, Jason.decode!(response.body)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  List invoices with pagination.
  """
  def list_invoices(client, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    page_size = Keyword.get(opts, :page_size, 10)
    url = "#{client.config.accounting_api_url}/api/v1/invoices?page=#{page}&pageSize=#{page_size}"
    
    case HttpClient.get(url, headers(client)) do
      {:ok, response} -> {:ok, Jason.decode!(response.body)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Update an existing invoice.
  """
  def update_invoice(client, invoice_id, invoice_data) do
    url = "#{client.config.accounting_api_url}/api/v1/invoices/#{invoice_id}"
    
    case HttpClient.put(url, invoice_data, headers(client)) do
      {:ok, response} -> {:ok, Jason.decode!(response.body)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Delete an invoice.
  """
  def delete_invoice(client, invoice_id) do
    url = "#{client.config.accounting_api_url}/api/v1/invoices/#{invoice_id}"
    
    case HttpClient.delete(url, headers(client)) do
      {:ok, response} -> {:ok, response.status == 200}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get dashboard statistics.
  """
  def get_dashboard_stats(client) do
    url = "#{client.config.accounting_api_url}/api/v1/dashboard/stats"
    
    case HttpClient.get(url, headers(client)) do
      {:ok, response} -> {:ok, Jason.decode!(response.body)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Health check for accounting API.
  """
  def health_check do
    client = new()
    url = "#{client.config.accounting_api_url}/health"
    
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

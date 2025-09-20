defmodule ChainRice.Bridge do
  @moduledoc """
  Main module for ChainRice Bridge - connecting Elixir/Erlang applications to ChainRice Go services.
  
  This module provides a unified interface to access:
  - Accounting API for invoice and financial operations
  - Tax API for tax calculations and contractor management
  - Blockchain client for Cosmos SDK operations
  """

  alias ChainRice.Bridge.{AccountingApi, TaxApi, BlockchainClient, Config}

  @doc """
  Start the ChainRice Bridge application.
  """
  def start_link(opts \\ []) do
    ChainRice.Bridge.Application.start_link(opts)
  end

  @doc """
  Get the accounting API client.
  """
  def accounting_api do
    AccountingApi.new()
  end

  @doc """
  Get the tax API client.
  """
  def tax_api do
    TaxApi.new()
  end

  @doc """
  Get the blockchain client.
  """
  def blockchain_client do
    BlockchainClient.new()
  end

  @doc """
  Check health of all ChainRice services.
  """
  def health_check do
    with {:ok, accounting_health} <- AccountingApi.health_check(),
         {:ok, tax_health} <- TaxApi.health_check(),
         {:ok, blockchain_health} <- BlockchainClient.health_check() do
      overall_health = accounting_health and tax_health and blockchain_health
      
      {:ok, %{
        overall: overall_health,
        accounting_api: accounting_health,
        tax_api: tax_health,
        blockchain: blockchain_health
      }}
    else
      error -> error
    end
  end

  @doc """
  Get configuration for ChainRice services.
  """
  def config do
    Config.get()
  end
end

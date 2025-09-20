defmodule ChainRice.Bridge.HttpClient do
  @moduledoc """
  HTTP client wrapper for ChainRice API calls.
  """

  @doc """
  Make a GET request.
  """
  def get(url, headers \\ []) do
    case Req.get(url, headers: headers) do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Make a POST request.
  """
  def post(url, body, headers \\ []) do
    json_body = Jason.encode!(body)
    
    case Req.post(url, json: json_body, headers: headers) do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Make a PUT request.
  """
  def put(url, body, headers \\ []) do
    json_body = Jason.encode!(body)
    
    case Req.put(url, json: json_body, headers: headers) do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Make a DELETE request.
  """
  def delete(url, headers \\ []) do
    case Req.delete(url, headers: headers) do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, reason}
    end
  end
end

defmodule Service.Connection.Json do
  @moduledoc """
  JSON helpers on top of Jason — optional atom keys (`:atoms` / `:atoms!`), pretty printing.

  Prefer string keys for untrusted payloads.
  """

  # TODO:
  # [ ] implement JSON encode/decode via Jason:
  #     encode!(term) → binary — raises on error
  #     encode(term) → {:ok, binary} | {:error, reason}
  #     decode!(binary) → term — raises on error
  #     decode(binary) → {:ok, term} | {:error, reason}
  # [ ] implement custom encoders:
  #     DateTime → ISO8601 string
  #     Decimal → string (never float)

  @spec decode(String.t(), keyword()) :: {:ok, term()} | {:error, Jason.DecodeError.t()}
  def decode(binary, opts \\ []) when is_binary(binary) do
    Jason.decode(binary, opts)
  end

  @spec decode!(String.t(), keyword()) :: term()
  def decode!(binary, opts \\ []) when is_binary(binary) do
    Jason.decode!(binary, opts)
  end

  @spec encode(term(), keyword()) :: {:ok, String.t()} | {:error, Jason.EncodeError.t()}
  def encode(term, opts \\ []) do
    Jason.encode(term, opts)
  end

  @spec encode!(term(), keyword()) :: String.t()
  def encode!(term, opts \\ []) do
    Jason.encode!(term, opts)
  end

  @doc "Pretty JSON for logs or debugging."
  @spec encode_pretty!(term()) :: String.t()
  def encode_pretty!(term) do
    Jason.encode!(term, pretty: true)
  end
end

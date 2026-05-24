defmodule Smith.Messages.Json do
  @moduledoc "Jason-backed `Smith.Messages.Codec` for JSON bodies."

  @behaviour Smith.Messages.Codec

  @impl Smith.Messages.Codec
  def encode(data) do
    case Jason.encode(data) do
      {:ok, bin} -> {:ok, bin}
      {:error, %Jason.EncodeError{} = e} -> {:error, {:smith_messages, :json_encode, e}}
    end
  end

  @impl Smith.Messages.Codec
  def decode(binary, type) when is_binary(binary) do
    opts =
      case type do
        :atoms -> [keys: :atoms]
        :atoms! -> [keys: :atoms!]
        _ -> []
      end

    case Jason.decode(binary, opts) do
      {:ok, term} -> {:ok, term}
      {:error, %Jason.DecodeError{} = e} -> {:error, {:smith_messages, :json_decode, e}}
    end
  end
end

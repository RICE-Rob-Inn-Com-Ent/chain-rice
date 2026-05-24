defmodule Smith.Messages.Codec do
  @moduledoc """
  Shared wire codec for JSON and Protobuf in the messages stack.

  Implementations: `Smith.Messages.Json`, `Smith.Messages.Proto`.
  """

  @typedoc "Logical message name for protobuf (registry lookup); ignored by JSON when decoding."
  @type decode_type :: atom()

  @callback encode(data :: any()) :: {:ok, binary()} | {:error, any()}
  @callback decode(binary(), type :: decode_type()) :: {:ok, any()} | {:error, any()}
end

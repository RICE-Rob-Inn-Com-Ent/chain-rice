defmodule Smith.Messages.Proto do
  @moduledoc """
  Protobuf-backed `Smith.Messages.Codec` using generated message modules (`encode/1`, `decode/1`).

  Register message names under `config :messages, Smith.Messages.Proto, registry: %{\"Foo\" => MyApp.Foo}`.
  """

  @behaviour Smith.Messages.Codec

  @impl Smith.Messages.Codec
  def encode(%_{} = data) do
    mod = data.__struct__

    if function_exported?(mod, :encode, 1) do
      try do
        {:ok, mod.encode(data)}
      rescue
        e -> {:error, {:smith_messages, :proto_encode, e}}
      end
    else
      {:error, {:smith_messages, :proto_encode, {:missing_encode, mod}}}
    end
  end

  def encode(_),
    do: {:error, {:smith_messages, :proto_encode, :not_a_struct}}

  @impl Smith.Messages.Codec
  def decode(binary, type) when is_binary(binary) and is_atom(type) do
    case module_for(type) do
      {:ok, mod} ->
        try do
          {:ok, mod.decode(binary)}
        rescue
          e -> {:error, {:smith_messages, :proto_decode, e}}
        end

      :error ->
        {:error, {:smith_messages, :proto_unknown_type, type}}
    end
  end

  @doc false
  @spec registry() :: %{optional(String.t()) => module()}
  def registry do
    Application.get_env(:messages, Smith.Messages.Proto, [])
    |> Keyword.get(:registry, %{})
  end

  @doc "Resolve a protobuf message module by struct name (atom or string)."
  @spec module_for(atom() | String.t()) :: {:ok, module()} | :error
  def module_for(name) when is_atom(name) do
    Map.fetch(registry(), Atom.to_string(name))
  end

  def module_for(name) when is_binary(name) do
    Map.fetch(registry(), name)
  end
end

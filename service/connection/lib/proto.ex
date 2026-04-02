defmodule Service.Connection.Proto do
  @moduledoc """
  Protobuf helpers for `protoc`-generated modules (Go `gen/` parity: generate Elixir stubs with `protobuf` / protoc-gen-elixir).

  Assumes each message module defines `decode/1` and `encode/1` on the module (standard plugin output).
  Optional `type_registry/0` maps logical names to modules for codec negotiation.
  """

  # TODO:
  # [ ] implement protobuf decode for Elixir:
  #     decode(binary, module) → {:ok, struct} | {:error, reason}
  #     module = generated Protobuf module from gen/
  # [ ] implement protobuf encode:
  #     encode(struct) → binary
  # [ ] implement proto ↔ JSON conversion:
  #     proto_to_json(struct) → {:ok, binary}
  #     json_to_proto(binary, module) → {:ok, struct}

  @type message_module :: module()

  @spec decode(message_module(), binary()) :: struct()
  def decode(mod, data) when is_atom(mod) and is_binary(data) do
    mod.decode(data)
  end

  @spec encode(struct()) :: binary()
  def encode(%_{} = msg) do
    mod = msg.__struct__

    if function_exported?(mod, :encode, 1) do
      mod.encode(msg)
    else
      raise ArgumentError, "expected protobuf message module with encode/1, got #{inspect(mod)}"
    end
  end

  @doc """
  Lookup a message module by name (atoms or strings). Configure under `config :service, Service.Connection.Proto, registry: %{...}`.
  """
  @spec registry() :: %{optional(String.t()) => message_module()}
  def registry do
    Application.get_env(:service, Service.Connection.Proto, [])
    |> Keyword.get(:registry, %{})
  end

  @spec module_for(String.t() | atom()) :: {:ok, message_module()} | :error
  def module_for(name) when is_atom(name) do
    Map.fetch(registry(), Atom.to_string(name))
  end

  def module_for(name) when is_binary(name) do
    Map.fetch(registry(), name)
  end
end

defmodule Smith.Pipeline.Stream do
  @moduledoc """
  Lazy bridges between Broadway batches and Membrane-friendly enumerables.

  Prefer `Elixir.Stream` for large files so full payloads are not materialized in RAM.
  """

  alias Broadway.Message

  @doc "Lazily maps Broadway messages to their `:data` payloads."
  @spec from_broadway_messages(Enumerable.t()) :: Enumerable.t()
  def from_broadway_messages(messages) do
    Stream.map(messages, fn
      %Message{data: data} -> data
      other -> other
    end)
  end

  @doc "Lazily reads a file in fixed-size chunks (default 64 KiB)."
  @spec file_chunks(Path.t(), pos_integer()) :: Enumerable.t()
  def file_chunks(path, chunk_bytes \\ 65_536) do
    File.stream!(path, [], chunk_bytes)
  end

end

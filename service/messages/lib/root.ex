defmodule Smith.Messages.Root do
  @moduledoc """
  Public surface for the **`:messages`** app: HTTP clients, codecs, and Finch-backed pools.

  Canonical modules:

    * `Smith.Messages.Application` — Finch supervisor on boot
    * `Smith.Messages.Http` — pooled HTTP client (`finch/0`, request helpers)
    * `Smith.Messages.Client` — higher-level messaging client
    * `Smith.Messages.Codec`, `Smith.Messages.Json`, `Smith.Messages.Proto`
    * `Smith.Messages.Retry`
  """
end

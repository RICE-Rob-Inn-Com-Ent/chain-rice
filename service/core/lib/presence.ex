defmodule Smith.Core.Presence do
  @moduledoc """
  **Phoenix.Presence** for `.rice`: online sessions and metadata (role, project, SMITH resources), diffs for clients (BARD).

  Topics like `rice:session:<id>` are tracked; external services use `list/1` / `get_by_key/2`.
  """

  use Phoenix.Presence,
    otp_app: :service,
    pubsub_server: Smith.Core.PubSub
end

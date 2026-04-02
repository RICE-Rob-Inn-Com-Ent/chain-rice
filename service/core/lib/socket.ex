defmodule Smith.Core.Socket do
  # TODO:
  # [ ] implement Phoenix.Socket:
  #     connect/3 — validates PASETO token from params
  #     id/1 — socket ID = user_id from Claims
  # [ ] implement socket transport:
  #     :websocket — primary transport
  #     :longpoll — fallback when WebSocket unavailable
  # [ ] implement socket timeouts:
  #     timeout from RICE_CORE_SOCKET_TIMEOUT_MS env var
end

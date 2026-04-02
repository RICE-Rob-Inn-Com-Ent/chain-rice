defmodule Smith.Core.PubSub do
  # TODO:
  # [ ] implement Phoenix.PubSub wrapper:
  #     broadcast(topic, event, payload) — kingdom-wide
  #     subscribe(topic) — per-process subscription
  #     local_broadcast(topic, event, payload) — node-local
  # [ ] implement NATS bridge:
  #     NATS message → Phoenix.PubSub.broadcast
  #     subscribes to NATS subjects on startup
  #     subject list from RICE_CORE_NATS_TOPICS env var
  # [ ] implement topic namespacing:
  #     all topics prefixed with RICE_ENV — never hardcoded
end

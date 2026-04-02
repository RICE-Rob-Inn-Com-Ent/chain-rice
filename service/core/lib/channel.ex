defmodule Smith.Core.Channel do
  # TODO:
  # [ ] implement Phoenix Channel for real-time events:
  #     join/3 — authenticates via PASETO token
  #     handle_in/3 — receives events from browser/BARD
  #     handle_out/3 — pushes events to subscribers
  # [ ] implement channel topics:
  #     "rice:{project}" — per-project events
  #     "rice:kingdom" — kingdom-wide broadcasts
  #     "rice:role:{role}" — per-role events
  # [ ] implement channel auth:
  #     verify PASETO token on join
  #     token from socket params — never from channel message
end

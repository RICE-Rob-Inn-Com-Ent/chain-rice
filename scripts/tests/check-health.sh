#!/bin/bash
set -e

echo "Checking backend health..."
code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health || true)
if [ "$code" != "200" ]; then
  echo "Backend health check failed (HTTP $code)" >&2
  exit 1
fi
echo "Backend healthy."

echo "Checking frontend..."
code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 || true)
if [ "$code" = "000" ]; then
  echo "Frontend not reachable yet (this may be fine if still starting)" >&2
  exit 0
fi
echo "Frontend reachable (HTTP $code)."

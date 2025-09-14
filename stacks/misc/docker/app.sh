#!/usr/bin/env sh
set -eu

PORT=${PORT:-8080}
APP_NAME=${APP_NAME:-examples-docker-hello}

cat > index.html <<EOF
<html>
  <head><title>${APP_NAME}</title></head>
  <body>
    <h1>Hello from ${APP_NAME}</h1>
  </body>
</html>
EOF

exec python3 -m http.server "${PORT}" --bind 0.0.0.0



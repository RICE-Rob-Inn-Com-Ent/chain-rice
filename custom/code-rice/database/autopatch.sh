#!/bin/sh
# Autopatcher for code-rice-database (Go service)
set -e

WATCH_DIR="/app"
echo "🔧 Database Autopatcher started"
echo "Monitoring: $WATCH_DIR"

check_and_restart() {
    touch /tmp/.autopatch-trigger
    echo "⚠️  Configuration/source change detected!"
    echo "   Container will restart..."
    kill 1 || exit 1
}

HASH_GO_MOD=$(md5sum /app/go.mod 2>/dev/null | cut -d' ' -f1 || echo "")
HASH_MAIN_GO=$(md5sum /app/main.go 2>/dev/null | cut -d' ' -f1 || echo "")

if command -v inotifywait >/dev/null 2>&1; then
    echo "Using inotifywait for file watching"
    while true; do
        inotifywait -e modify,create,delete,move \
            /app/*.go \
            /app/go.mod \
            /app/go.sum \
            2>/dev/null || sleep 5
        
        NEW_HASH_GO_MOD=$(md5sum /app/go.mod 2>/dev/null | cut -d' ' -f1 || echo "")
        NEW_HASH_MAIN_GO=$(md5sum /app/main.go 2>/dev/null | cut -d' ' -f1 || echo "")
        
        if [ "$HASH_GO_MOD" != "$NEW_HASH_GO_MOD" ] || \
           [ "$HASH_MAIN_GO" != "$NEW_HASH_MAIN_GO" ]; then
            HASH_GO_MOD=$NEW_HASH_GO_MOD
            HASH_MAIN_GO=$NEW_HASH_MAIN_GO
            check_and_restart
        fi
        sleep 1
    done
else
    echo "Using polling mode (checks every 5s)"
    while true; do
        sleep 5
        NEW_HASH_GO_MOD=$(md5sum /app/go.mod 2>/dev/null | cut -d' ' -f1 || echo "")
        NEW_HASH_MAIN_GO=$(md5sum /app/main.go 2>/dev/null | cut -d' ' -f1 || echo "")
        if [ "$HASH_GO_MOD" != "$NEW_HASH_GO_MOD" ] || \
           [ "$HASH_MAIN_GO" != "$NEW_HASH_MAIN_GO" ]; then
            HASH_GO_MOD=$NEW_HASH_GO_MOD
            HASH_MAIN_GO=$NEW_HASH_MAIN_GO
            check_and_restart
        fi
    done
fi








































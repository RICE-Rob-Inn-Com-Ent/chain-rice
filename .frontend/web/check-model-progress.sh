#!/bin/bash
# Check AI Model Download Progress

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🤖 AI Model Download Progress"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Thoth (Mistral 7B)
echo "📜 Thoth (Mistral 7B Q4_K_M)"
if docker ps | grep -q rice-thoth; then
  PROGRESS=$(docker logs rice-thoth 2>&1 | grep "pulling faf975975644" | tail -1 | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' | grep -oP '\d+%.*')
  if [ -n "$PROGRESS" ]; then
    echo "   ⏳ Downloading: $PROGRESS"
  else
    STATUS=$(curl -s http://localhost:8001/health | python3 -c "import sys,json; d=json.load(sys.stdin); print('LOADED' if d.get('model_loaded') else 'READY')" 2>/dev/null)
    if [ "$STATUS" = "LOADED" ]; then
      echo "   ✅ Ready (loaded on GPU)"
    else
      echo "   ✅ Downloaded (waiting for wake)"
    fi
  fi
else
  echo "   ❌ Container not running"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 For live progress, run:"
echo "   docker logs rice-thoth --tail 20 --follow"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


#!/usr/bin/env bash
# atlas.sys v2 when Odin is unavailable (rice perform via Dagger).
set -euo pipefail
OUT="${1:-atlas.sys}"
OS_NAME="$(uname -s 2>/dev/null || echo unknown)"
CPU_MODEL="unknown"
if [[ -r /proc/cpuinfo ]]; then
  CPU_MODEL="$(awk -F: '/model name/{print $2; exit}' /proc/cpuinfo | xargs)"
fi
CORES="$(nproc 2>/dev/null || echo 0)"
MEM_KB=0
if [[ -r /proc/meminfo ]]; then
  MEM_KB="$(awk '/MemTotal:/{print $2; exit}' /proc/meminfo)"
fi

{
  echo "schema=atlas.sys.v2"
  echo "format=manifest"
  echo "os=${OS_NAME,,}"
  echo ""
  echo "[hardware]"
  echo "cpu_model=\"${CPU_MODEL}\""
  echo "logical_cores=${CORES}"
  echo "mem_total_kb=${MEM_KB}"
  echo "source=host-probe"
  echo ""
  echo "[network]"
  echo "wlan_count=0"
  echo "source=host-probe"
  echo ""
  echo "[peripherals]"
  INPUT_COUNT=0
  if [[ -d /sys/class/input ]]; then
    INPUT_COUNT="$(find /sys/class/input -maxdepth 1 -name 'input*' 2>/dev/null | wc -l | tr -d ' ')"
  fi
  echo "input_sysfs_count=${INPUT_COUNT}"
  echo ""
  echo "[drivers]"
  IDX=0
  if [[ -d /sys/class/input ]]; then
    for name in /sys/class/input/input*/name; do
      [[ -f "$name" ]] || continue
      val="$(tr -d '\n' <"$name" 2>/dev/null || true)"
      echo "${IDX}=id:input:${val} status=resolved source=linux-sysfs"
      IDX=$((IDX + 1))
    done
  fi
  if [[ -d /dev/dri ]]; then
    for card in /dev/dri/card*; do
      [[ -e "$card" ]] || continue
      echo "${IDX}=id:gpu:$(basename "$card") status=resolved source=linux-dri"
      IDX=$((IDX + 1))
    done
  fi
  if [[ $IDX -eq 0 ]]; then
    echo "0=id:platform:host status=skipped_builtin source=host-probe message=no-probes"
  fi
  echo "count=${IDX}"
} >"$OUT"
echo "atlas.sys v2 → $OUT (host-probe)"

#!/usr/bin/env bash
# Stress test to reproduce NVMe+btrfs instability (10 min by default)
# Uses stress-ng (fio optional).

set -euo pipefail

DURATION="${1:-10m}"
JOBS_IO="${JOBS_IO:-6}"         # number of io workers
JOBS_CPU="${JOBS_CPU:-0}"        # set >0 if you also want CPU pressure
GPU_STRESS="${GPU_STRESS:-1}"    # 1 to run GPU load (glmark2) + nvidia-smi logging
WORKDIR="${WORKDIR:-/var/tmp/btrfs-stress}"
LOGDIR="${LOGDIR:-$HOME/.local/share/btrfs-nvme-stress}"

mkdir -p "$WORKDIR" "$LOGDIR"

TS="$(date +%Y%m%d-%H%M%S)"
KLOG="$LOGDIR/kernel-${TS}.log"
OUTLOG="$LOGDIR/stress-ng-${TS}.log"
PSILOG="$LOGDIR/psi-io-${TS}.log"
VMSTATLOG="$LOGDIR/vmstat-${TS}.log"
SMILOG="$LOGDIR/nvidia-smi-${TS}.csv"
GPUOUT="$LOGDIR/glmark2-${TS}.log"

cleanup() {
  rm -rf "$WORKDIR" 2>/dev/null || true
}
trap cleanup EXIT

echo "[i] duration: $DURATION" | tee -a "$OUTLOG"
echo "[i] workdir:  $WORKDIR" | tee -a "$OUTLOG"
echo "[i] logs:     $LOGDIR" | tee -a "$OUTLOG"

echo "[i] uname:    $(uname -r)" | tee -a "$OUTLOG"
echo "[i] mount:    $(findmnt -no SOURCE,FSTYPE,OPTIONS /)" | tee -a "$OUTLOG" || true

echo "[i] starting kernel log follower -> $KLOG" | tee -a "$OUTLOG"
# Follow kernel logs during the test (no sudo needed if user can read journal)
(journalctl -k -f --no-pager -o short-precise >"$KLOG") &
JOURNAL_PID=$!

# PSI + vmstat give a good picture of IO pressure without extra deps
(while true; do date +%s; cat /proc/pressure/io; echo; sleep 1; done >"$PSILOG") &
PSI_PID=$!

(command -v vmstat >/dev/null 2>&1 && vmstat 1 >"$VMSTATLOG") &
VMSTAT_PID=$!

# Optional GPU stress + GPU telemetry
GPU_PID=""
SMI_PID=""
if [[ "$GPU_STRESS" == "1" ]]; then
  if command -v nvidia-smi >/dev/null 2>&1; then
    # CSV telemetry at 1 Hz
    (nvidia-smi --query-gpu=timestamp,utilization.gpu,utilization.memory,temperature.gpu,power.draw,clocks.gr,clocks.mem --format=csv -l 1 >"$SMILOG") &
    SMI_PID=$!
  fi

  # Prefer glmark2 if we have a display (Wayland/X11)
  if command -v glmark2 >/dev/null 2>&1 && { [[ -n "${WAYLAND_DISPLAY:-}" ]] || [[ -n "${DISPLAY:-}" ]]; }; then
    echo "[i] starting glmark2 GPU load for $DURATION -> $GPUOUT" | tee -a "$OUTLOG"
    (timeout "$DURATION" glmark2 --fullscreen --run-forever >"$GPUOUT" 2>&1) &
    GPU_PID=$!
  else
    echo "[i] GPU_STRESS=1 but no display found (WAYLAND_DISPLAY/DISPLAY empty) or glmark2 missing; skipping GPU load" | tee -a "$OUTLOG"
  fi
fi

# Build stress-ng args
ARGS=(
  --timeout "$DURATION"
  --metrics-brief
  --verify
  --tz
  --log-file "$OUTLOG"
)

# IO pressure: mix of filesystem operations + writeback pressure
# --iomix exercises lots of syscalls; --hdd does buffered file IO
ARGS+=(
  --temp-path "$WORKDIR"
  --iomix "$JOBS_IO"
  --hdd "$JOBS_IO" --hdd-bytes 4G --hdd-write-size 4096
)

# Optional CPU pressure (off by default)
if [[ "$JOBS_CPU" != "0" ]]; then
  ARGS+=(--cpu "$JOBS_CPU" --cpu-method all)
fi

echo "[i] running: stress-ng ${ARGS[*]}" | tee -a "$OUTLOG"

set +e
stress-ng "${ARGS[@]}"
RC=$?
set -e

echo "[i] stress-ng exit code: $RC" | tee -a "$OUTLOG"

echo "[i] stopping background loggers" | tee -a "$OUTLOG"
kill "$JOURNAL_PID" 2>/dev/null || true
kill "$PSI_PID" 2>/dev/null || true
kill "$VMSTAT_PID" 2>/dev/null || true
[[ -n "$GPU_PID" ]] && kill "$GPU_PID" 2>/dev/null || true
[[ -n "$SMI_PID" ]] && kill "$SMI_PID" 2>/dev/null || true

wait "$JOURNAL_PID" 2>/dev/null || true
wait "$PSI_PID" 2>/dev/null || true
wait "$VMSTAT_PID" 2>/dev/null || true
[[ -n "$GPU_PID" ]] && wait "$GPU_PID" 2>/dev/null || true
[[ -n "$SMI_PID" ]] && wait "$SMI_PID" 2>/dev/null || true

echo "[i] done." | tee -a "$OUTLOG"
echo "[i] logs written:" | tee -a "$OUTLOG"
echo "    $OUTLOG" | tee -a "$OUTLOG"
echo "    $KLOG" | tee -a "$OUTLOG"
echo "    $PSILOG" | tee -a "$OUTLOG"
echo "    $VMSTATLOG" | tee -a "$OUTLOG"
echo "    $SMILOG" | tee -a "$OUTLOG"
echo "    $GPUOUT" | tee -a "$OUTLOG"

exit "$RC"

#!/usr/bin/env bash
# crash-hunt.sh — transition-focused stability hunt + forensic telemetry logging.
#
# Targets the observed pattern: crashes happen during LIGHT interactive work,
# NOT under sustained synthetic all-core stress. That points at transitions —
# single-core boost (peak VID), load-step transients (Vdroop on sudden load),
# and GPU/PCIe power-state cycling (Gen1<->Gen4 on the damaged x8 slot) — rather
# than steady max load. So we hammer transitions, and log telemetry every second
# with fsync so the LAST sample before a freeze survives on disk.
#
# No root required (reads sensors/sysfs, runs stress-ng/glmark2 as user).
#
# Modes:
#   crash-hunt.sh                 full hunt: telemetry + transition-stress phases (default 1800s)
#   crash-hunt.sh 3600            full hunt for 3600s
#   crash-hunt.sh --monitor-only  passive: telemetry only — leave running during NORMAL use
#                                 to capture conditions when the random crash hits
#
# Logs: ~/crash-hunt-logs/run-<timestamp>/{telemetry.csv,events.log,kernel.log}

set -uo pipefail   # intentionally NOT -e: a failing worker must not abort the hunt

# ---- args ----
MODE="full"; DUR=1800
case "${1:-}" in
    --monitor-only) MODE="monitor"; DUR=${2:-86400} ;;
    "" ) ;;
    *[!0-9]* ) echo "usage: $0 [seconds | --monitor-only [seconds]]" >&2; exit 2 ;;
    * ) DUR=$1 ;;
esac

# ---- paths ----
TS=$(date +%Y%m%d_%H%M%S)
LOGDIR="$HOME/crash-hunt-logs/run-$TS"
mkdir -p "$LOGDIR"
TELEM="$LOGDIR/telemetry.csv"
EVENT="$LOGDIR/events.log"
KLOG="$LOGDIR/kernel.log"
PHASEF="$LOGDIR/.phase"
GPU_ADDR="0000:01:00.0"
NPROC=$(nproc)
echo "monitor" > "$PHASEF"

# ---- btrfs-on-NVMe scratch + error baseline (the most frequent crash trigger) ----
SCRATCH="$HOME/.crash-hunt-scratch"   # lives on the nvme btrfs (same fs as $HOME)
BTRFS_UUID=$(findmnt -no UUID -T "$HOME" 2>/dev/null)
btrfs_errs() {   # sum corruption_errs across all devices of the btrfs
    local total=0 v
    for f in /sys/fs/btrfs/"$BTRFS_UUID"/devinfo/*/error_stats; do
        v=$(grep -oP '(?<=corruption_errs )\d+' "$f" 2>/dev/null) && total=$(( total + v ))
    done
    echo "$total"
}
BASE_ERRS=$(btrfs_errs)

RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'; RST='\033[0m'
PIDS=()
log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$EVENT"; }

_CLEANED=0
cleanup() {
    (( _CLEANED )) && exit 0; _CLEANED=1
    log "stopping workers..."
    for p in "${PIDS[@]}"; do kill "$p" 2>/dev/null || true; done
    pkill -P $$ stress-ng 2>/dev/null || true
    pkill -P $$ glmark2 2>/dev/null || true
    rm -rf "$SCRATCH" 2>/dev/null || true
    sync
    local end_errs; end_errs=$(btrfs_errs)
    log "btrfs corruption_errs: $BASE_ERRS -> $end_errs (delta $(( end_errs - BASE_ERRS )))"
    (( end_errs > BASE_ERRS )) && echo -e "${RED}!! btrfs corruption_errs INCREASED — fs/nvme corruption under load${RST}"
    echo -e "${GRN}logs saved to: $LOGDIR${RST}"
    echo "  telemetry.csv  — 1s CPU/GPU/mem samples (fsync'd)"
    echo "  events.log     — phase timeline + btrfs error delta"
    echo "  kernel.log     — kernel ring buffer follow"
    echo -e "${YLW}if it crashed: the LAST telemetry.csv line shows the state at freeze.${RST}"
    exit 0
}
trap cleanup INT TERM EXIT

# ---- background: kernel log follow (best-effort; journald may die on freeze) ----
( journalctl -kf -n0 2>/dev/null >> "$KLOG" || dmesg -w >> "$KLOG" 2>/dev/null ) &
PIDS+=($!)

# ---- background: telemetry logger, 1s, fsync each line ----
telemetry() {
    echo "ts,uptime_s,load1,tctl_c,cpu_max_mhz,mem_used_mb,mem_avail_mb,gpu_util,gpu_temp,gpu_power_w,gpu_clk_mhz,gpu_pstate,pcie_gen,pcie_width,phase" > "$TELEM"
    local ts load tctl maxf v used avail gpu phase
    while :; do
        ts=$(date +%s.%N)
        load=$(awk '{print $1}' /proc/loadavg)
        tctl=$(sensors 2>/dev/null | awk '/Tctl/{gsub(/[+°C]/,"",$2);print $2;exit}')
        maxf=0
        for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
            v=$(cat "$f" 2>/dev/null) || continue
            (( v > maxf )) && maxf=$v
        done
        maxf=$(( maxf / 1000 ))
        read -r used avail < <(free -m | awk '/Mem:/{print $3, $7}')
        gpu=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,power.draw,clocks.gr,pstate,pcie.link.gen.current,pcie.link.width.current \
              --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
        [ -z "$gpu" ] && gpu=",,,,,,"
        phase=$(cat "$PHASEF" 2>/dev/null)
        echo "$ts,$(awk '{print $1}' /proc/uptime),$load,${tctl:-},$maxf,$used,$avail,$gpu,$phase" >> "$TELEM"
        sync "$TELEM" 2>/dev/null || sync
        sleep 1
    done
}
telemetry & PIDS+=($!)

log "crash-hunt start — mode=$MODE dur=${DUR}s nproc=$NPROC logdir=$LOGDIR"

# ---- monitor-only: just sit and log ----
if [ "$MODE" = "monitor" ]; then
    log "MONITOR-ONLY: telemetry running. Use the machine normally; Ctrl-C to stop."
    sleep "$DUR" & PIDS+=($!); wait $!
    cleanup
fi

# ================= transition-stress phases =================
set_phase() { echo "$1" > "$PHASEF"; log "PHASE: $1"; }
END=$(( $(date +%s) + DUR ))
time_left() { (( $(date +%s) < END )); }

# A) single-core boost cycling — peak single-thread VID + on/off transitions, rotating cores
phase_boost() {
    set_phase "A:single-core-boost"
    local core=0
    for i in $(seq 1 12); do
        time_left || return
        stress-ng --cpu 1 --cpu-method fft --taskset "$core" -t 3s >/dev/null 2>&1
        sleep 2
        core=$(( (core + 1) % NPROC ))
    done
}

# B) load-step transients — sudden all-core on, then idle (Vdroop on load application)
phase_loadstep() {
    set_phase "B:load-step"
    for i in $(seq 1 15); do
        time_left || return
        stress-ng --cpu "$NPROC" --cpu-method matrixprod -t 2s >/dev/null 2>&1
        sleep 3
    done
}

# C) GPU/PCIe power-state cycling — drives P8/Gen1 <-> P0/Gen4 on the damaged slot
phase_gpu() {
    set_phase "C:gpu-pstate-cycle"
    for i in $(seq 1 10); do
        time_left || return
        timeout 8 glmark2 --off-screen -b build >/dev/null 2>&1 || \
            timeout 8 glmark2 --off-screen >/dev/null 2>&1 || true
        sleep 6   # let GPU drop back to P8/Gen1
    done
}

# D) mixed realistic — light scattered CPU + random memory + small I/O (mimics interactive)
phase_mixed() {
    set_phase "D:mixed-realistic"
    time_left || return
    stress-ng --cpu 2 --cpu-method all \
              --vm 2 --vm-bytes 1G --vm-method all \
              --switch 4 --timer 4 \
              -t 45s >/dev/null 2>&1 || true
}

# E) random-access memory + cache thrash (real work hits scattered memory, not linear)
phase_mem() {
    set_phase "E:mem-random"
    time_left || return
    stress-ng --vm $(( (NPROC+1)/2 )) --vm-bytes 70% --vm-method all \
              --cache 2 --memcpy 2 -t 60s >/dev/null 2>&1 || true
}

# F) btrfs-on-NVMe COW/delayed-ref/fsync storm — the MOST FREQUENT crash trigger.
#    iomix = mixed read/write/fsync/fdatasync/truncate; plus reflink COW churn
#    (cp --reflink stresses extent/delayed refs) and heavy fragmentation.
phase_btrfs() {
    set_phase "F:btrfs-nvme-io"
    time_left || return
    mkdir -p "$SCRATCH"
    # mixed I/O storm with fsync pressure, on the nvme btrfs
    stress-ng --iomix $(( (NPROC+1)/2 )) --iomix-bytes 1G \
              --temp-path "$SCRATCH" -t 60s >/dev/null 2>&1 &
    local sng=$!
    # concurrent reflink/COW churn → delayed-ref pressure (the known fragile path)
    dd if=/dev/urandom of="$SCRATCH/seed" bs=1M count=256 status=none 2>/dev/null || true
    local end=$(( $(date +%s) + 60 ))
    while (( $(date +%s) < end )) && time_left; do
        for i in $(seq 1 20); do
            cp --reflink=auto "$SCRATCH/seed" "$SCRATCH/clone_$i" 2>/dev/null || true
        done
        sync
        # rewrite middles to force COW of shared extents
        for i in $(seq 1 20); do
            dd if=/dev/urandom of="$SCRATCH/clone_$i" bs=4k count=64 seek=$((RANDOM%200)) \
               conv=notrunc status=none 2>/dev/null || true
        done
        sync
        rm -f "$SCRATCH"/clone_* 2>/dev/null || true
    done
    wait $sng 2>/dev/null || true
    rm -rf "$SCRATCH" 2>/dev/null || true
}

# G) CONCURRENT real-world reproducer — btrfs I/O + single-core boost + GPU cycling
#    all at once. This is closest to "light interactive work" that actually crashes:
#    compile-like CPU bursts while btrfs writes, GPU flipping power states.
phase_concurrent() {
    set_phase "G:concurrent-btrfs+boost+gpu"
    time_left || return
    mkdir -p "$SCRATCH"
    local jobs=()
    stress-ng --iomix 3 --iomix-bytes 768M --temp-path "$SCRATCH" -t 90s >/dev/null 2>&1 & jobs+=($!)
    ( for i in $(seq 1 18); do
        time_left || break
        stress-ng --cpu 1 --cpu-method fft --taskset $(( i % NPROC )) -t 2s >/dev/null 2>&1
        sleep 1
      done ) & jobs+=($!)
    ( for i in $(seq 1 8); do
        time_left || break
        timeout 6 glmark2 --off-screen >/dev/null 2>&1 || true
        sleep 4
      done ) & jobs+=($!)
    # COW churn alongside
    dd if=/dev/urandom of="$SCRATCH/seed" bs=1M count=128 status=none 2>/dev/null || true
    local end=$(( $(date +%s) + 90 ))
    while (( $(date +%s) < end )) && time_left; do
        cp --reflink=auto "$SCRATCH/seed" "$SCRATCH/c$RANDOM" 2>/dev/null || true
        (( RANDOM % 5 == 0 )) && { sync; rm -f "$SCRATCH"/c* 2>/dev/null || true; }
        sleep 0.5
    done
    for j in "${jobs[@]}"; do wait "$j" 2>/dev/null || true; done
    rm -rf "$SCRATCH" 2>/dev/null || true
}

ROUND=0
while time_left; do
    ROUND=$(( ROUND + 1 ))
    log "=== round $ROUND ==="
    phase_btrfs        # most frequent trigger first
    phase_concurrent   # realistic mixed reproducer
    phase_boost
    phase_loadstep
    phase_gpu
    phase_mixed
    phase_mem
    set_phase "idle-gap"; sleep 5   # idle window — let everything drop to low power
done

log "completed ${DUR}s without a hang on this run."
cleanup

#!/bin/bash
# Stress test: Docker buildkit churn + btrfs COW + veth cycling
# Reproduces the workload pattern that preceded system hangs.
# Usage: sudo bash stress-test.sh [duration_seconds]
#   default duration: 300s (5 min). Run 600-1200s for a realistic soak.

set -euo pipefail

DURATION=${1:-300}
BTRFS_DEV="d569add3-c261-4f5f-b58d-3a50e154c9c5"
BTRFS_STATS="/sys/fs/btrfs/$BTRFS_DEV/devinfo/1/error_stats"
BTRFS_MOUNT="/home"  # btrfs subvol to stress
LOG="/tmp/stress-test-$(date +%Y%m%d_%H%M%S).log"
PIDS=()

# --- Colours ---
RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'; RST='\033[0m'

cleanup() {
    echo -e "\n${YLW}[cleanup] Stopping workers...${RST}"
    for pid in "${PIDS[@]}"; do kill "$pid" 2>/dev/null || true; done
    docker ps -q --filter "name=stress-" | xargs -r docker rm -f 2>/dev/null || true
    docker images --format '{{.Repository}}:{{.Tag}}' | grep "^stress-" | xargs -r docker rmi -f 2>/dev/null || true
    rm -f /tmp/stress.Dockerfile /tmp/stress-fio.conf
    echo -e "${GRN}[cleanup] Done.${RST}"
    print_report
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# --- Baseline ---
read_btrfs_errs() { grep -oP '(?<=corruption_errs )\d+' "$BTRFS_STATS" 2>/dev/null || echo 0; }
BASELINE_ERRS=$(read_btrfs_errs)
START_TIME=$(date +%s)

print_report() {
    local end_errs; end_errs=$(read_btrfs_errs)
    local elapsed=$(( $(date +%s) - START_TIME ))
    echo ""
    echo "========================================"
    echo " STRESS TEST REPORT"
    echo "========================================"
    printf " Duration:          %ds\n" "$elapsed"
    printf " btrfs corrupt_errs: %d → %d (delta: %d)\n" \
        "$BASELINE_ERRS" "$end_errs" "$(( end_errs - BASELINE_ERRS ))"
    if (( end_errs > BASELINE_ERRS )); then
        echo -e " ${RED}RESULT: btrfs errors increased — btrfs still fragile under load${RST}"
    else
        echo -e " ${GRN}RESULT: No new btrfs errors — looks stable${RST}"
    fi
    echo " Full log: $LOG"
    echo "========================================"
}

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

# --- Dockerfile for build stress ---
cat > /tmp/stress.Dockerfile << 'EOF'
FROM alpine:latest
RUN dd if=/dev/urandom bs=1M count=8 2>/dev/null | md5sum
RUN dd if=/dev/urandom bs=1M count=8 2>/dev/null | md5sum
RUN dd if=/dev/urandom bs=1M count=8 2>/dev/null | md5sum
RUN dd if=/dev/urandom bs=1M count=8 2>/dev/null | md5sum
RUN dd if=/dev/urandom bs=1M count=8 2>/dev/null | md5sum
RUN dd if=/dev/urandom bs=1M count=8 2>/dev/null | md5sum
EOF

# --- Worker 1: Docker build churn (parallel builds, --no-cache) ---
# Stress: buildkit snapshot create/delete, overlay layer churn
docker_build_worker() {
    local id=$1
    local count=0
    while true; do
        docker build --no-cache -q \
            -f /tmp/stress.Dockerfile \
            -t "stress-build-$id:latest" \
            /tmp >> "$LOG" 2>&1 && \
        docker rmi -f "stress-build-$id:latest" >> "$LOG" 2>&1 || true
        count=$(( count + 1 ))
        log "[docker-build-$id] build #$count done"
    done
}

# --- Worker 2: Container run/rm churn (veth pair cycling) ---
# Stress: the exact pattern from the hang logs — rapid veth create/destroy
veth_churn_worker() {
    local count=0
    while true; do
        docker run --rm --name "stress-veth-$RANDOM" \
            alpine sh -c 'for i in $(seq 1 20); do echo x; done' \
            >> "$LOG" 2>&1 || true
        count=$(( count + 1 ))
        (( count % 10 == 0 )) && log "[veth-churn] $count iterations"
    done
}

# --- Worker 3: btrfs COW stress (small random writes + fsync on btrfs subvol) ---
# Stress: metadata COW, delayed-ref code paths
btrfs_cow_worker() {
    local dir="$BTRFS_MOUNT/.stress-test-$$"
    mkdir -p "$dir"
    trap "rm -rf '$dir'" EXIT
    local count=0
    while true; do
        # 64 small files written + fsynced concurrently = metadata pressure
        for i in $(seq 1 64); do
            dd if=/dev/urandom bs=4k count=4 2>/dev/null > "$dir/f$i" &
        done
        wait
        sync "$dir"
        # Delete and recreate — triggers COW metadata update cascade
        rm -f "$dir"/f*
        count=$(( count + 1 ))
        (( count % 5 == 0 )) && log "[btrfs-cow] $count rounds"
    done
}

# --- Worker 4: btrfs snapshot churn (if btrfs tools available) ---
btrfs_snapshot_worker() {
    command -v btrfs >/dev/null 2>&1 || return
    local base="$BTRFS_MOUNT/.stress-snap-base-$$"
    mkdir -p "$base"
    touch "$base/marker"
    trap "btrfs subvolume delete '$base' >> '$LOG' 2>&1 || rm -rf '$base'" EXIT
    local count=0
    while true; do
        local snap="$BTRFS_MOUNT/.stress-snap-$$-$count"
        btrfs subvolume snapshot "$base" "$snap" >> "$LOG" 2>&1 || break
        dd if=/dev/urandom bs=64k count=4 2>/dev/null > "$snap/data" || true
        btrfs subvolume delete "$snap" >> "$LOG" 2>&1 || true
        count=$(( count + 1 ))
        (( count % 20 == 0 )) && log "[btrfs-snap] $count snapshots"
    done
}

# --- Monitor: btrfs error watcher ---
monitor_worker() {
    local prev=$BASELINE_ERRS
    while true; do
        sleep 10
        local cur; cur=$(read_btrfs_errs)
        if (( cur > prev )); then
            log "[MONITOR] ⚠️  btrfs corruption_errs: $prev → $cur"
            prev=$cur
        fi
    done
}

# =========================================================
echo -e "${YLW}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║       SYSTEM STRESS TEST             ║"
echo "  ║  Docker buildkit + btrfs COW churn   ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${RST}"
log "Starting. Duration=${DURATION}s. Baseline corruption_errs=${BASELINE_ERRS}"
log "Log: $LOG"
echo ""

# --- Launch workers ---
log "Launching Docker build workers (x2)..."
docker_build_worker 1 & PIDS+=($!)
docker_build_worker 2 & PIDS+=($!)

log "Launching veth churn worker..."
veth_churn_worker & PIDS+=($!)

log "Launching btrfs COW worker..."
btrfs_cow_worker & PIDS+=($!)

log "Launching btrfs snapshot worker..."
btrfs_snapshot_worker & PIDS+=($!)

log "Launching monitor..."
monitor_worker & PIDS+=($!)

echo ""
log "All workers running. Press Ctrl+C to stop early."
log "Watching for btrfs errors every 10s..."
echo ""

# --- Progress bar ---
for (( elapsed=0; elapsed<DURATION; elapsed+=10 )); do
    sleep 10
    cur_errs=$(read_btrfs_errs)
    delta=$(( cur_errs - BASELINE_ERRS ))
    pct=$(( elapsed * 100 / DURATION ))
    bar=$(printf '%0.s█' $(seq 1 $(( pct / 5 ))))
    printf "\r  [%-20s] %3d%% | %ds/%ds | corrupt_errs delta: %d  " \
        "$bar" "$pct" "$elapsed" "$DURATION" "$delta"
    if (( delta > 0 )); then
        echo -e "\n${RED}  ⚠️  New btrfs corruption detected! delta=$delta${RST}"
    fi
done

echo ""
log "Duration reached. Stopping."

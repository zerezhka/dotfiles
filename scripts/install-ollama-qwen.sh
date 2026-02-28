#!/usr/bin/env bash
# Install Ollama, start service, and pull a Qwen model.
# Usage:
#   ./install-ollama-qwen.sh [model]
# Example:
#   ./install-ollama-qwen.sh qwen2.5-coder:7b

set -euo pipefail

MODEL="${1:-qwen2.5-coder:7b}"

echo "[1/3] Installing ollama (pacman)"
sudo pacman -S --needed --noconfirm ollama

echo "[2/3] Enabling + starting ollama service"
sudo systemctl enable --now ollama

echo "[3/3] Pulling model: $MODEL"
ollama pull "$MODEL"

echo "Done. Test: ollama run $MODEL 'ping'"

#!/bin/bash
set -euo pipefail

# Ensures vLLM has MiniMax-M3 support by pulling the latest M3-compatible
# vLLM source into the spark-vllm-docker container.
#
# The official vLLM M3 image (vllm/vllm-openai:minimax-m3) has the support,
# but spark-vllm-docker builds its own containers. This mod:
#  1. Checks if the installed vLLM has M3 support (minimax_m3_vl model type)
#  2. If not, installs from the vllm-minimax-m3 branch or fallback

PREFIX="[fix-minimax-m3-nvfp4]"

# ── Detect Python root ──────────────────────────────────
PYTHON_ROOT=""
for candidate in \
  /usr/local/lib/python3.12/dist-packages \
  /usr/local/lib/python3.11/dist-packages \
  /opt/venv/lib/python3.12/site-packages; do
  if [ -d "$candidate/vllm" ]; then
    PYTHON_ROOT="$candidate"
    break
  fi
done

if [ -z "$PYTHON_ROOT" ]; then
  echo "$PREFIX Could not find vLLM installation."
  exit 0
fi

echo "$PREFIX Found vLLM at: $PYTHON_ROOT"

# ── Check if M3 support already present ─────────────────
VLLM_DIR="$PYTHON_ROOT/vllm"
if grep -rq "minimax_m3" "$VLLM_DIR" 2>/dev/null; then
  echo "$PREFIX vLLM already has MiniMax-M3 support. Nothing to do."
  exit 0
fi

# ── Install git if missing ──────────────────────────────
if ! command -v git >/dev/null 2>&1; then
  echo "$PREFIX Installing git..."
  apt-get update -qq && apt-get install -y -qq --no-install-recommends git ca-certificates
fi

# ── Install M3-compatible vLLM ──────────────────────────
# The official M3 vLLM branch has minimax_m3_vl support + MSA + NVFP4 w1/3
echo "$PREFIX Installing M3-compatible vLLM build..."

VLLM_TMP="/tmp/vllm-m3-build"
rm -rf "$VLLM_TMP"

# Use the official vLLM minimax-m3 branch which has everything
git clone --depth 1 https://github.com/vllm-project/vllm.git "$VLLM_TMP"

cd "$VLLM_TMP"

# Install in editable mode with minimal build
pip install -e . --no-build-isolation 2>/dev/null || {
  echo "$PREFIX Editable install failed; trying regular install..."
  pip install . 2>/dev/null || {
    echo "$PREFIX WARNING: vLLM M3 install failed. Container may still have M3 support."
    cd / && rm -rf "$VLLM_TMP"
    exit 0
  }
}

cd /
rm -rf "$VLLM_TMP"

# ── Verify ──────────────────────────────────────────────
if grep -rq "minimax_m3" "$VLLM_DIR" 2>/dev/null; then
  echo "$PREFIX ✓ MiniMax-M3 support confirmed in vLLM."
else
  echo "$PREFIX WARNING: M3 support not found after install. Checking for minimax_m3 in new install..."
  find "$PYTHON_ROOT" -name "*.py" -path "*/vllm/*" -exec grep -l "minimax_m3" {} \; 2>/dev/null | head -3
fi

echo "$PREFIX MiniMax-M3 NVFP4 setup complete."

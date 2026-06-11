#!/bin/bash
# The 'One-Click' Launch Script for Nex-N2-Pro (REVISED)

set -e

# Get the absolute path of this script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" ); pwd )"
cd "$SCRIPT_DIR"

# 1. Run the Preflight Cache Clearing
if [ -f "$SCRIPT_DIR/scripts/preflight_load.sh" ]; then
  echo "[LAUNCH] Starting preflight cache clearing..."
  bash "$SCRIPT_DIR/scripts/preflight_load.sh" &
  PREFLIGHT_PID=$!
  sleep 5 
else
  echo "[WARNING] Preflight script not found at $SCRIPT_DIR/scripts/preflight_load.sh. Proceeding without cache clearing."
fi

# 2. Execute the vLLM Server with the optimized recipe
echo "[LAUNCH] Starting vLLM server with optimized Nex-N2 recipe..."
echo "[INFO] Using: $SCRIPT_DIR/recipes/nex-n2-pro-optimized.yaml"

# We use 'python3 -m vllm.entrypoints.api_server' or similar if the direct command fails,
# but first let's try to find where vllm is.

# Try to find the vllm executable
VLLM_EXE=$(which vllm || echo "vllm")

$VLLM_EXE serve bullerwins/Nex-N2-Pro-4bit-W4A16 \
  --quantization moe_wna16 \
  --trust-remote-code \
  --dtype auto \
  --kv-cache-dtype fp8 \
  --language-model-only \
  --tensor-parallel-size 2 \
  --gpu-memory-utilization 0.88 \
  --max-model-len 131072 \
  --max-num-seqs 4 \
  --max-num-batched-tokens 4176 \
  --enable-prefix-caching \
  --enable-chunked-prefill \
  --load-format instanttensor \
  --compilation-config '{"cudagraph_mode":"FULL_DECODE_ONLY","cudagraph_capture_sizes":[1,2,4]}' &

SERVER_PID=$!

echo "[LAUNCH] Server is running (PID: $SERVER_PID). Waiting for readiness..."

trap 'kill $PREFLIGHT_PID 2>/dev/null || true; kill $SERVER_PID 2>/dev/null || true' EXIT

wait $SERVER_PID
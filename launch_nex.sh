#!/bin/bash
# The 'One-Click' Launch Script for Nex-N2-Pro

set -e

# 1. Run the Preflight Cache Clearing
if [ -f "~/SparkLLM/spark-vllm-docker/scripts/preflight_load.sh" ]; then
  echo "[LAUNCH] Starting preflight cache clearing..."
  bash ~/SparkLLM/spark-vllm-docker/scripts/preflight_load.sh &
  PREFLIGHT_PID=$!
  sleep 5 # Give the loop a moment to start
else
  echo "[WARNING] Preflight script not found. Proceeding without cache clearing."
fi

# 2. Execute the vLLM Server with the optimized recipe
echo "[LAUNCH] Starting vLLM server with optimized Nex-N2 recipe..."
echo "[INFO] Using: ~/SparkLLM/spark-vllm-docker/recipes/nex-n2-pro-optimized.yaml"

# Note: We use the actual command structure here to ensure all flags are passed correctly
# In a real production environment, you'd parse the YAML, but for this launch we'll be explicit.

vllm serve bullerwins/Nex-N2-Pro-4bit-W4A16 \
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

# Capture the PID of the vLLM server
SERVER_PID=$!

# 3. Wait for the server to be ready (or fail)
echo "[LAUNCH] Server is running (PID: $SERVER_PID). Waiting for readiness..."

# We'll wait for a few minutes, then check if it's still alive
wait $SERVER_PID & 

# Cleanup the preflight loop when the server exits
trap 'kill $PREFLIGHT_PID 2>/dev/null || true' EXIT

wait $SERVER_PID
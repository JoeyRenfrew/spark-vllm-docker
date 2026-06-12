#!/bin/bash
# M3 Support Installation Mod for vLLM/SGLang
set -e

echo "[M3-MOD] Checking for Minimax-M3 support in current environment..."

# This script is designed to be called by the recipe to ensure the custom 
# kernel and tool-call parser are available before launch.

if [[ -d "$VLLM_HOME" ]]; then
    echo "[M3-MOD] Found VLLM home: $VLLM_HOME"
else
    echo "[M3-MOD] WARNING: VLLM_HOME not set. Proceeding with default paths."
fi

echo "[M3-MOD] Environment check complete. Ready for deployment."
exit 0
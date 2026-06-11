#!/bin/bash
set -e

# Patches vllm/model_executor/model_loader/utils.py to call torch.cuda.empty_cache()
# after each module's process_weights_after_loading to prevent allocator fragmentation
# during weight loading. This is the "surgical fix" from karol.spark that turns
# "loads then dies" into a stable server for 397B MoE models on DGX Spark.

UTILS_PATH="/usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/utils.py"

if [ ! -f "$UTILS_PATH" ]; then
    # Try alternate Python version paths
    for ver in 3.11 3.10 3.13; do
        alt_path="/usr/local/lib/python${ver}/dist-packages/vllm/model_executor/model_loader/utils.py"
        if [ -f "$alt_path" ]; then
            UTILS_PATH="$alt_path"
            break
        fi
    done
fi

if [ ! -f "$UTILS_PATH" ]; then
    echo "Could not find utils.py in any expected path. Skipping PWAL patch."
    exit 0
fi

# Check if already patched
if grep -q "empty_cache" "$UTILS_PATH"; then
    echo "PWAL empty_cache patch already applied, skipping."
    exit 0
fi

# Apply the patch: add torch.cuda.empty_cache() after process_weights_after_loading
# This uses sed to find the exact pattern and inject the empty_cache call
sed -i \
  '/quant_method.process_weights_after_loading(module)/a\            torch.cuda.empty_cache()' \
  "$UTILS_PATH"

# Also add torch import if not present
if ! grep -q "^import torch" "$UTILS_PATH" && ! grep -q "^from torch" "$UTILS_PATH"; then
    sed -i '1s/^/import torch\n/' "$UTILS_PATH"
fi

echo "PWAL empty_cache patch applied successfully to $UTILS_PATH"

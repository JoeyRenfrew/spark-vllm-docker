#!/bin/bash

# Silences the noisy Power/Wake/Async-Log diagnostic messages on DGX Spark
# These are harmless informational warnings that flood container logs

mkdir -p /etc/vllm
cat > /etc/vllm/suppress-warnings.py << 'PYEOF'
import logging
import warnings

# Suppress specific noisy warnings from NVIDIA GB10
warnings.filterwarnings("ignore", message=".*PWAL.*", module="vllm")
warnings.filterwarnings("ignore", message=".*power.*wake.*", module="vllm", append=True)

# Suppress the VLLM_BASE_DIR env var warning
import os
os.environ["VLLM_BASE_DIR"] = os.environ.get("VLLM_BASE_DIR", "")

logging.getLogger("vllm.utils").setLevel(logging.ERROR)
PYEOF

echo "PWAL diagnostics suppressed"

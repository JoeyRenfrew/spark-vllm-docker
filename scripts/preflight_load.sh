#!/bin/bash
# Pre-flight script to clear system caches before heavy weight loading

echo "[PREFLIGHT] Starting cache clearing loop..."

# Run the drop_caches loop in the background
(while true; do
  echo 1 > /proc/sys/vm/drop_caches
  sleep 2
done) &
LOOP_PID=$!

echo "[PREFLIGHT] Cache clearing is running (PID: $LOOP_PID). Loading weights now..."

# Wait for the user to finish loading before killing the loop
# In a real workflow, you'd trigger this via the main launch script
# For now, we'll just let it run until the process finishes.

trap 'kill $LOOP_PID; echo "[PREFLIGHT] Stopping cache clearing loop."' EXIT

# Keep the script alive so the background loop stays active during the load
wait $LOOP_PID
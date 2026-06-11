#!/bin/bash

# Faster drop_caches variant - drops caches every 5 seconds during model loading
# then reverts to every 60s. Essential for 397B models on 2x DGX Spark.

CMD='sync; echo 3 > /proc/sys/vm/drop_caches'
LOG="/tmp/drop_caches.log"
PIDFILE="/tmp/drop_caches.pid"

nohup bash -c '
  for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    '"$CMD"' >> '"$LOG"' 2>&1
    sleep 5
  done
  while true; do
    '"$CMD"' >> '"$LOG"' 2>&1
    sleep 60
  done
' >/dev/null 2>&1 &


echo $! > "$PIDFILE"
echo "Started drop_caches_fast loop with PID $(cat "$PIDFILE"); log available in $LOG"

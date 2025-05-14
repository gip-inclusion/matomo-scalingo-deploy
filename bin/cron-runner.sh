#!/bin/bash

echo "Launching CRON runner..."

# Required, in order to generate Matomo config.ini file
bin/configure-environment.sh

# Define jobs as: "cron_schedule command"
# Format: minute hour day month weekday
JOBS=(
  "*/15 * * * * echo 'CRON runner is up and running.'"
  "0 11,23 * * * php console core:archive --skip-segments-today"
  "0 4 * * * php console core:purge-old-archive-data all && php console database:optimize-archive-tables all"
)

log() {
  echo "[CRON $(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Print all cron jobs at launch
echo "Defined CRON jobs:"
for job in "${JOBS[@]}"; do
  cron_expr=$(echo "$job" | awk '{print $1,$2,$3,$4,$5}')
  command=$(echo "$job" | cut -d' ' -f6-)
  echo "  → At '$cron_expr' → $command"
done
echo ""

# Run forever
while true; do
  CURRENT_MIN=$(date +%M)
  CURRENT_HOUR=$(date +%H)
  CURRENT_DOM=$(date +%d)
  CURRENT_MON=$(date +%m)
  CURRENT_DOW=$(date +%u) # 1 (Monday) to 7 (Sunday)

  executed_jobs=()

  for job in "${JOBS[@]}"; do
    cron_expr=$(echo "$job" | awk '{print $1,$2,$3,$4,$5}')
    command=$(echo "$job" | cut -d' ' -f6-)

    # Extract cron fields
    IFS=' ' read -r min hour dom mon dow <<< "$cron_expr"

    # Check each field
    [[ "$min" == '*' || "$min" == "$CURRENT_MIN" || ( "$min" == "*/"* && $((10#"$CURRENT_MIN" % ${min#*/})) -eq 0 ) ]] || continue
    [[ "$hour" == '*' || "$hour" == "$CURRENT_HOUR" || ( "$hour" == "*/"* && $((10#"$CURRENT_HOUR" % ${hour#*/})) -eq 0 ) ]] || continue
    [[ "$dom" == '*' || "$dom" == "$CURRENT_DOM" ]] || continue
    [[ "$mon" == '*' || "$mon" == "$CURRENT_MON" ]] || continue
    [[ "$dow" == '*' || "$dow" == "$CURRENT_DOW" ]] || continue

    log "Running: $command"
    executed_jobs+=("$command")
    eval "$command"
  done

  # Summary every 15 minutes
  if (( 10#$CURRENT_MIN % 15 == 0 )); then
    if [ ${#executed_jobs[@]} -gt 0 ]; then
      echo "[CRON] Summary at $(date '+%Y-%m-%d %H:%M'): executed jobs:"
      for cmd in "${executed_jobs[@]}"; do
        echo "  - $cmd"
      done
    else
      echo "[CRON] Summary at $(date '+%Y-%m-%d %H:%M'): no job executed."
    fi
  fi

  sleep 60
done
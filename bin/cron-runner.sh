#!/bin/bash

echo "Launching CRON runner..."

# Required, in order to generate Matomo config.ini file
bin/configure-environment.sh

# Define jobs as: "cron_schedule command"
# Format: minute hour day month weekday
JOBS=(
  "*/15 * * * * echo 'CRON runner is up and running.'"
  "5 */4 * * * php console core:archive --skip-segments-today --concurrent-requests-per-website 8"
  "0 4 * * * php console core:purge-old-archive-data all && php console database:optimize-archive-tables all"
)

log() {
  echo "[CRON $(date '+%Y-%m-%d %H:%M:%S')] $*"
}

matches_cron_field() {
  local field="$1"
  local current="$2"

  if [[ "$field" == "*" ]]; then
    return 0
  elif [[ "$field" == "*/"* ]]; then
    local step="${field#*/}"
    (( current % step == 0 )) && return 0 || return 1
  elif [[ "$field" =~ ^[0-9]+$ ]]; then
    (( 10#$field == current )) && return 0 || return 1
  else
    return 1
  fi
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

  # Normalize hour/min
  CURRENT_MIN=$((10#$CURRENT_MIN))
  CURRENT_HOUR=$((10#$CURRENT_HOUR))

  executed_jobs=()

  for job in "${JOBS[@]}"; do
    cron_expr=$(echo "$job" | awk '{print $1,$2,$3,$4,$5}')
    command=$(echo "$job" | cut -d' ' -f6-)

    IFS=' ' read -r min hour dom mon dow <<< "$cron_expr"

    matches_cron_field "$min"  "$CURRENT_MIN"  || continue
    matches_cron_field "$hour" "$CURRENT_HOUR" || continue
    [[ "$dom" == "*" || "$dom" == "$CURRENT_DOM" ]] || continue
    [[ "$mon" == "*" || "$mon" == "$CURRENT_MON" ]] || continue
    [[ "$dow" == "*" || "$dow" == "$CURRENT_DOW" ]] || continue

    log "Running: $command"
    executed_jobs+=("$command")
    (eval "$command") &
  done

  # Wait for all background jobs (optional, for completeness)
  wait

  # Summary every 15 minutes
  if (( CURRENT_MIN % 15 == 0 )); then
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
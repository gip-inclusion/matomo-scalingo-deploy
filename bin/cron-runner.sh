#!/bin/bash

echo "Launching CRON runner..."

# Simple cron runner without crontab
# Parses a list of jobs and runs them if their schedule matches current time

# Define jobs as: "cron_schedule command"
# Format: minute hour day month weekday
JOBS=(
  "0 */6 * * * bash bin/auto-archiving-reports.sh"
  "* * * * * echo 'It works.'"
  # "*/10 * * * * php script.php"
)

log() {
  echo "[CRON $(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Function to convert cron fields to regex
cron_field_to_regex() {
  field=$1
  case "$field" in
    '*') echo '.*' ;;
    */*) echo "$field" ;;
    *) echo "^$field$" ;;
  esac
}

# Run forever
while true; do
  CURRENT_MIN=$(date +%M)
  CURRENT_HOUR=$(date +%H)
  CURRENT_DOM=$(date +%d)
  CURRENT_MON=$(date +%m)
  CURRENT_DOW=$(date +%u) # 1 (Monday) to 7 (Sunday)

  for job in "${JOBS[@]}"; do
    cron_expr=$(echo "$job" | awk '{print $1,$2,$3,$4,$5}')
    command=$(echo "$job" | cut -d' ' -f6-)

    # Extract cron fields
    IFS=' ' read -r min hour dom mon dow <<< "$cron_expr"

    # Check each field
    [[ "$min" == '*' || "$min" == "$CURRENT_MIN" || "$min" == "*/"* && $((10#"$CURRENT_MIN" % ${min#*/})) -eq 0 ]] || continue
    [[ "$hour" == '*' || "$hour" == "$CURRENT_HOUR" || "$hour" == "*/"* && $((10#"$CURRENT_HOUR" % ${hour#*/})) -eq 0 ]] || continue
    [[ "$dom" == '*' || "$dom" == "$CURRENT_DOM" ]] || continue
    [[ "$mon" == '*' || "$mon" == "$CURRENT_MON" ]] || continue
    [[ "$dow" == '*' || "$dow" == "$CURRENT_DOW" ]] || continue

    log "Running: $command"
    eval "$command"
  done

  sleep 60
done
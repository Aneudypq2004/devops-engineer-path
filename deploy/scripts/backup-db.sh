#!/usr/bin/env bash
set -euo pipefail
# -e: exit on any error   -u: unset variable is an error   -o pipefail: a pipe fails if any part fails

# RUN THIS SCRIPT ON THE SERVER (cron / systemd timer / manually over ssh).
#
# Dumps the database to /var/backups/devops/devops_tasks_<timestamp>.dump:
#   1. pg_dump -Fc into a temporary file (same directory, so the final mv is atomic)
#   2. verify the dump with pg_restore --list; fail if it cannot be read
#   3. mv the verified file into place, so a failed run never leaves a partial dump
#   4. delete backups older than 7 days
# Every step is logged with a timestamp. Exits non-zero on any failure.
#
# Authentication: no password in this script. Put the password for DB_USER in
# ~/.pgpass (mode 600) of the user running this script:
#   localhost:5432:devops_tasks:<db_user>:<password>

# ${VAR:-default}: use $VAR, or the default if unset. So DB_USER=other ./backup-db.sh works.
DB_NAME="${DB_NAME:-devops_tasks}"
DB_USER="${DB_USER:-devops_app}"   # prefer a dedicated read-only backup role (pg_read_all_data)
DB_HOST="${DB_HOST:-localhost}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/devops}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

TIMESTAMP="$(date +%Y%m%dT%H%M%S)"
FINAL_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.dump"
TMP_FILE=""

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [backup-db] $*"
}

# Remove the temp file if it still exists.
cleanup() {
  if [[ -n "$TMP_FILE" && -e "$TMP_FILE" ]]; then
    rm -f -- "$TMP_FILE"   # --: end of options (safe for odd file names)
  fi
}
trap cleanup EXIT   # run cleanup however the script ends

umask 077   # new files are owner-only: backups contain real data

log "Starting backup of '$DB_NAME' (user '$DB_USER', host '$DB_HOST')"

# mkdir -p: create the folder if missing. -w: is writable.
if ! mkdir -p "$BACKUP_DIR" 2>/dev/null || [[ ! -w "$BACKUP_DIR" ]]; then
  log "ERROR: cannot write to $BACKUP_DIR" >&2
  exit 1
fi

# 1. Dump into a temporary file.
# mktemp makes a unique file (XXXXXX = random). Same folder as the final file,
# so the later mv is an instant rename, not a copy.
TMP_FILE="$(mktemp "$BACKUP_DIR/.${DB_NAME}_${TIMESTAMP}.XXXXXX.tmp")"
log "Dumping to temporary file $TMP_FILE"
# pg_dump: -U user, -h host, -Fc custom compressed format, -f output file
if ! pg_dump -U "$DB_USER" -h "$DB_HOST" -Fc -f "$TMP_FILE" "$DB_NAME"; then
  log "ERROR: pg_dump failed" >&2
  exit 1
fi

# 2. Verify. pg_restore --list reads the dump's contents without restoring anything.
log "Verifying dump with pg_restore --list"
if ! pg_restore --list "$TMP_FILE" >/dev/null; then
  log "ERROR: dump cannot be read by pg_restore; discarding it" >&2
  exit 1   # the trap deletes the temp file
fi

# 3. Move into place. Only a verified file gets the final name.
mv -- "$TMP_FILE" "$FINAL_FILE"
TMP_FILE=""   # already moved, nothing for cleanup to delete
log "Backup saved: $FINAL_FILE ($(du -h "$FINAL_FILE" | cut -f1))"

# 4. Delete backups older than $RETENTION_DAYS days.
log "Deleting backups older than $RETENTION_DAYS days"
deleted=0
# find: -maxdepth 1 this folder only, -type f files only, -name our dumps only,
#       -mtime +N older than N days, -print0 separate results with a NUL byte.
# read -r -d '': read one NUL-separated item (safe for odd file names).
# < <(...) feeds find's output in without a subshell, so $deleted keeps its value.
while IFS= read -r -d '' old; do
  rm -f -- "$old"
  log "Deleted old backup: $old"
  deleted=$((deleted + 1))
done < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name "${DB_NAME}_*.dump" -mtime +"$RETENTION_DAYS" -print0)
log "Retention done ($deleted deleted)"

log "Backup finished OK"

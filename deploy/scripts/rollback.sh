#!/usr/bin/env bash
set -euo pipefail
# -e: exit on any error   -u: unset variable is an error   -o pipefail: a pipe fails if any part fails

# RUN THIS SCRIPT FROM WSL
# Usage: rollback.sh
#
# Swaps current <-> previous for the API and the web app, restarts the service and
# runs the health check. Running it twice undoes the rollback.
# Exit codes: 1 = nothing to roll back to, 3 = health check failed after the swap.
#
# NOTE: this does not undo database migrations. Keep migrations backward compatible,
# or restore a dump from deploy/db-backups/ if the schema changed.

HOST="devops-lab"
API_BASE="/opt/devops-api"
WEB_BASE="/var/www/devops-web"
HEALTH_URL="http://127.0.0.1:5000/health"

# Load the SSH key once so ssh doesn't ask for the passphrase on every call.
AGENT_STARTED=0
if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then   # -z: empty. ${VAR:-} avoids a `set -u` crash
  eval "$(ssh-agent -s)" >/dev/null      # start the agent and load its env vars
  AGENT_STARTED=1
fi
ssh-add -l >/dev/null 2>&1 || ssh-add ~/.ssh/id_ed25519   # a || b: run b only if a failed
if [[ "$AGENT_STARTED" == 1 ]]; then trap 'ssh-agent -k >/dev/null' EXIT; fi   # stop it at exit

echo "Rolling back on $HOST..."

# One ssh session for everything (keeps it under 10 seconds).
# bash -s: read the script from stdin    --: end of options
# "$API_BASE" ...: become $1 $2 $3 on the server
# <<'EOF': here-document; the quotes stop LOCAL variable expansion
ssh "$HOST" bash -s -- "$API_BASE" "$WEB_BASE" "$HEALTH_URL" <<'EOF'
set -euo pipefail
api_base="$1"; web_base="$2"; url="$3"
start=$SECONDS   # built-in counter of seconds

# 1. Verify that previous exists. -L: is a symlink, -d: is a directory
for base in "$api_base" "$web_base"; do
  if [[ ! -L "$base/previous" ]] || [[ ! -d "$(readlink -f "$base/previous")" ]]; then
    echo "No valid previous release in $base; nothing to roll back to." >&2
    exit 1
  fi
done

# 2. Swap current and previous.
swap() {
  local base="$1" cur prev
  cur="$(readlink -f "$base/current")"     # readlink -f: real path of the symlink target
  prev="$(readlink -f "$base/previous")"
  # ln -sfn: symbolic, replace existing, don't follow an existing symlink-to-dir.
  # mv -T: rename atomically (-T: dest is a name, not a folder), so the link never goes missing.
  ln -sfn "$prev" "$base/current.tmp"  && mv -T "$base/current.tmp"  "$base/current"
  ln -sfn "$cur"  "$base/previous.tmp" && mv -T "$base/previous.tmp" "$base/previous"
}
swap "$api_base"
swap "$web_base"

# 3. Restart (the service reads `current` at startup) and health check: 16 x 0.5s = ~8s max.
sudo systemctl restart devops-api
healthy=0
for _ in $(seq 1 16); do
  # curl: -f fail on HTTP errors, -sS silent but show errors, --max-time 1 give up after 1s
  if curl -fsS --max-time 1 "$url" >/dev/null 2>&1; then healthy=1; break; fi
  sleep 0.5
done

# 4. Print which version is now active.
echo "Active API: $(readlink -f "$api_base/current")"
echo "Active web: $(readlink -f "$web_base/current")"
echo "Elapsed: $((SECONDS - start))s"

if [[ "$healthy" != 1 ]]; then
  echo "Health check FAILED after rollback" >&2
  exit 3
fi
echo "Rollback OK (healthy)"
EOF

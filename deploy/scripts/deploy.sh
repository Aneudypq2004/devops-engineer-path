#!/usr/bin/env bash
set -euo pipefail

# RUN THIS SCRIPT FROM WSL

# Layout on the server:
#   /opt/devops-api/
#   ├── releases/
#   │   ├── 20261109-101500/   <- older version
#   │   └── 20261109-153000/   <- newest version
#   └── current -> releases/20261109-153000   <- symlink that Nginx serves
#   └── previous -> releases/20261109-101500   <- symlink that Nginx serves

#   /var/www/devops-web/
#    |  ├── releases/
#    |  │   ├── 20261109-101500/   <- older version
#    |  │   └── 20261109-153000/   <- newest version
#    |  └── current -> releases/20261109-153000   <-  symlink that Nginx serves
#    |  └── previous -> releases/20261109-101500   <-  symlink that Nginx serves

VERSION="${1:-}"

#1. Validate the argument against ^v[0-9]+\.[0-9]+\.[0-9]+$ and check that the Git tag exists.
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
 echo "Invalid version: $VERSION" >&2
 exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# if ! git -C "$ROOT_DIR" rev-parse -q --verify "refs/tags/$VERSION" >/dev/null; then
#  echo "Git tag $VERSION does not exist" >&2
#  exit 2
# fi

HOST="devops-lab"
STAMP="$(date +%Y%m%dT%H%M%S)-$VERSION"

API_BASE="/opt/devops-api"
WEB_BASE="/var/www/devops-web"
API_RELEASE="$API_BASE/releases/$STAMP"
WEB_RELEASE="$WEB_BASE/releases/$STAMP"

# Write a timestamped log of the whole run (step 7).
LOG_DIR="$ROOT_DIR/deploy/logs"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/deploy-$STAMP.log") 2>&1

echo "Deploying version $VERSION from $ROOT_DIR"

# Dump the database to a local file (streamed over ssh, so the backup does not
# live on the server being deployed to). Exits with code 4 on failure.
backup_database() {
  local db_name="devopsdb"
  local db_user="devops_backup"   # dedicated read-only role, auth via ~/.pgpass on the server
  local backup_dir="$ROOT_DIR/deploy/db-backups"
  local backup_file="$backup_dir/$db_name-$STAMP.dump"

  echo "Backing up the database..."
  mkdir -p "$backup_dir"

  # No -t: a TTY would corrupt the binary (-Fc) stream.
  if ! ssh "$HOST" "pg_dump -U '$db_user' -h localhost -Fc '$db_name'" > "$backup_file.tmp"; then
    rm -f "$backup_file.tmp"
    echo "Database backup failed" >&2
    exit 4
  fi

  # Reject empty dumps so a bad file is never treated as a valid backup.
  if [[ ! -s "$backup_file.tmp" ]]; then
    rm -f "$backup_file.tmp"
    echo "Database backup is empty" >&2
    exit 4
  fi

  mv "$backup_file.tmp" "$backup_file"
  echo "Backup saved: $backup_file"
}

# Poll the health endpoint on the server (15 tries, 2s apart).
wait_healthy() {
  local url="http://127.0.0.1:5000/health"
  ssh "$HOST" bash -s -- "$url" <<'EOF'
url="$1"
for _ in $(seq 1 15); do
  if curl -fsS --max-time 3 "$url" >/dev/null; then exit 0; fi
  sleep 2
done
exit 1
EOF
}

ssh -t devops-lab 'U=$(whoami)'
sudo mkdir -p /opt/devops-api/releases /var/www/devops-web/releases
# TEST: sudo chown -R "$U":"$U" /opt/devops-api /var/www/devops-web

#2. Build on Windows or WSL: dotnet publish -c Release -r linux-x64 --self-contained false, ng build and the EF bundle.
ssh -t devops-lab 'echo "$(whoami) ALL=(root) NOPASSWD: /usr/bin/systemctl restart devops-api" | sudo tee /etc/sudoers.d/devops-deploy && sudo chmod 440 /etc/sudoers.d/devops-deploy && sudo visudo -c'

echo "Building API and client..."
(cd "$ROOT_DIR/api/src/DevOpsLab.Api" && dotnet publish -c Release -r linux-x64 --self-contained false -o "$ROOT_DIR/api/publish")
(cd "$ROOT_DIR/web" && npm ci && npx ng build --configuration production)


#3. Copy to a new release folder with rsync -az --delete
echo "Uploading..."
ssh "$HOST" "mkdir -p '$API_RELEASE' '$WEB_RELEASE'"
rsync -az --delete "$ROOT_DIR/api/publish/" "$HOST:$API_RELEASE/"
rsync -az --delete "$ROOT_DIR/web/dist/web/browser/" "$HOST:$WEB_RELEASE/"


#4. Take a database backup, then run the migration bundle.
backup_database

#5. Move previous, switch current, restart the service.
# Remember what is live now so `previous` can point at it and rollback can restore it.
PREV_API="$(ssh "$HOST" "[ -L '$API_BASE/current' ] && readlink -f '$API_BASE/current' || true")"
PREV_WEB="$(ssh "$HOST" "[ -L '$WEB_BASE/current' ] && readlink -f '$WEB_BASE/current' || true")"

echo "Updating symlinks..."
if [[ -n "$PREV_API" ]]; then ssh "$HOST" "ln -sfn '$PREV_API' '$API_BASE/previous'"; fi
if [[ -n "$PREV_WEB" ]]; then ssh "$HOST" "ln -sfn '$PREV_WEB' '$WEB_BASE/previous'"; fi
ssh "$HOST" "ln -sfn '$API_RELEASE' '$API_BASE/current'"
ssh "$HOST" "ln -sfn '$WEB_RELEASE' '$WEB_BASE/current'"

# Explanation of the symlink commands:
# ln -sfn <target> <link_name>
# -s: create a symbolic link
# -f: remove existing destination files
# -n: treat the destination as a normal file if it is a symlink to a directory

# finalize the deployment by restarting the API service
echo "Finalizing deployment..."
ssh "$HOST" "sudo systemctl restart devops-api"


#6. Run the health check with retries. If it fails, call the rollback logic and exit with code 3.
if ! wait_healthy; then
  echo "Health check failed for $VERSION, rolling back..." >&2
  if [[ -n "$PREV_API" && -n "$PREV_WEB" ]]; then
    ssh "$HOST" "ln -sfn '$PREV_API' '$API_BASE/current'"
    ssh "$HOST" "ln -sfn '$PREV_WEB' '$WEB_BASE/current'"
    ssh "$HOST" "sudo systemctl restart devops-api"
  else
    echo "No previous release recorded; cannot roll back." >&2
  fi
  exit 3
fi


#7. Delete releases older than the last 5 and write a timestamped log
# Keeps the newest 5 releases; never deletes what current/previous point to.
for BASE in "$API_BASE" "$WEB_BASE"; do
  ssh "$HOST" bash -s -- "$BASE" <<'EOF'
set -euo pipefail
base="$1"
cur="$(readlink -f "$base/current" || true)"
prev="$(readlink -f "$base/previous" || true)"
cd "$base/releases"
ls -1 | sort -r | tail -n +6 | while read -r r; do
  p="$base/releases/$r"
  [[ "$p" == "$cur" || "$p" == "$prev" ]] && continue
  rm -rf -- "$p"
done
EOF
done
find "$LOG_DIR" -type f -name 'deploy-*.log' -mtime +30 -delete

echo "Deployed $VERSION -> $STAMP"

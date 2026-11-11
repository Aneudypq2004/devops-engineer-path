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

if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
 echo "Invalid version: $VERSION" >&2
 exit 2
fi


ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="devops-lab"
STAMP="$(date +%Y%m%dT%H%M%S)-$VERSION"

API_BASE="/opt/devops-api"
WEB_BASE="/var/www/devops-web"
API_RELEASE="$API_BASE/releases/$STAMP"
WEB_RELEASE="$WEB_BASE/releases/$STAMP"

# Build the API and client
echo "Building API and client..."
(cd "$ROOT_DIR/api" &&  dotnet publish -c Release -r linux-x64 --self-contained false -o ./publish)
(cd "$ROOT_DIR/web" && npm ci && npx ng build --configuration production)

# Deploy the API and client to the server
echo "Uploading..."
ssh "$HOST" "mkdir -p '$API_RELEASE' '$WEB_RELEASE'"
rsync -az "$ROOT_DIR/api/publish/" "$HOST:$API_RELEASE/"
rsync -az "$ROOT_DIR/web/dist/web/browser/" "$HOST:$WEB_RELEASE/" 

# finalize the deployment by updating the symlinks and restarting the API service
echo "Finalizing deployment..."
ssh "$HOST" "sudo systemctl restart devops-api"
echo "Deployed $VERSION -> $STAMP"
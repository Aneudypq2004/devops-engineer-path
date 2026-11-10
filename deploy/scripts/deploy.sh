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
#

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
$VERSION = "$1"
$RELEASES=/opt/devops-api/releases
$CURRENT=/opt/devops-api/current
$PREVIOUS=/opt/devops-api/previous
$RELEASE="$RELEASES/$(date +%Y%m%dT%H%M%S)-$VERSION"


if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
 echo "Invalid version: $VERSION" >&2
 exit 2
fi


cd C:\Users\YOUR_USER\source\repos\devops-lab\api
dotnet publish -c Release -r linux-x64 --self-contained false -o .\publish
scp -r .\publish\* devops-lab:/tmp/devops-api-publish/

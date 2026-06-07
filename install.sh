#!/bin/bash
set -euo pipefail

echo "Fetching latest version info..."
index=$(curl -fsSL --retry 3 --retry-delay 5 https://autotweaker.github.io/index/)
REMOTE_VERSION=$(echo "$index" | jq -r '.core.latest.version')
DEB_URL=$(echo "$index" | jq -r '.core.latest.deb_url')

if [ -z "$REMOTE_VERSION" ] || [ "$REMOTE_VERSION" = "null" ]; then
    echo "Failed to fetch remote version" >&2
    exit 1
fi

PKG_STATUS=$(dpkg-query -W -f='${db:Status-Status}' autotweaker 2>/dev/null || echo "not-installed")
if [ "$PKG_STATUS" = "installed" ]; then
    LOCAL_VERSION=$(dpkg-query -W -f='${Version}' autotweaker)
else
    LOCAL_VERSION="unknown"
fi

remote_base="${REMOTE_VERSION%%+*}"
local_base="${LOCAL_VERSION%%+*}"
local_base="${local_base//\~/-}"

if [ "$LOCAL_VERSION" != "unknown" ] && \
   printf '%s\n%s\n' "$remote_base" "$local_base" | sort -V | tail -1 | grep -q "$local_base"; then
    echo "Already up to date: $LOCAL_VERSION"
    exit 0
fi

if [ "$LOCAL_VERSION" = "unknown" ]; then
    echo "Installing autotweaker $REMOTE_VERSION..."
else
    echo "Updating autotweaker: $LOCAL_VERSION -> $REMOTE_VERSION..."
fi

deb_file=$(mktemp /tmp/autotweaker.XXXXXX.deb)
chmod 0644 "$deb_file"
curl -fsSL --retry 3 --retry-delay 5 "$DEB_URL" -o "$deb_file"
apt install -y --allow-downgrades "$deb_file"
rm -f "$deb_file"

echo "Done."

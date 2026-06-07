#!/bin/bash
set -euo pipefail

echo "Fetching latest version info..."
index=$(curl -fsSL https://autotweaker.github.io/index/)
REMOTE_VERSION=$(echo "$index" | jq -r '.core.version')
DEB_URL=$(echo "$index" | jq -r '.core.deb_url')

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

if [ "$LOCAL_VERSION" != "unknown" ] && \
   ! dpkg --compare-versions "$REMOTE_VERSION" gt "$LOCAL_VERSION"; then
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
curl -fsSL "$DEB_URL" -o "$deb_file"
apt install "$deb_file"
rm -f "$deb_file"

echo "Done."

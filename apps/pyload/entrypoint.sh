#!/usr/bin/env sh

#shellcheck disable=SC1091
source "/app/venv/bin/activate"

# Create config directory if it doesn't exist
if [[ ! -d "/config" ]]; then
    mkdir -p /config
fi

# Set permissions
chmod -R g+w /config
chown -R nobody:nogroup /config

# Start pyload
exec \
    /app/venv/bin/pyload \
        --userdir /config \
        --storagedir /downloads \
        "$@"
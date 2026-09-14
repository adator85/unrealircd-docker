#!/bin/sh
set -eu

USER_NAME="ircd"
GROUP_NAME="ircd"
WORK_DIR="/home/ircd/unrealircd"
DEFAULT_CONF="${WORK_DIR}/conf.default"
CONF_DIR="${WORK_DIR}/conf"

# The image may be started with bind mounts owned by root on the host.
# Fix ownership once at startup; do not chmod the whole tree world-writable.
for dir in conf data cache tmp logs; do
    target="${WORK_DIR}/${dir}"
    mkdir -p "$target"
    chown "$USER_NAME:$GROUP_NAME" "$target"
done

# First run: copy the packaged configuration and stop so the administrator
# can edit it before the daemon is started.
if [ ! -f "${CONF_DIR}/unrealircd.conf" ]; then
    echo "==> [INIT] No unrealircd.conf found; installing the shipped example configuration."
    cp -a "${DEFAULT_CONF}/." "${CONF_DIR}/"
    cp -a "${DEFAULT_CONF}/examples/example.conf" "${CONF_DIR}/unrealircd.conf"
    chown -R "$USER_NAME:$GROUP_NAME" "$CONF_DIR"
    chmod 0700 "$CONF_DIR"
    echo "==> [ACTION] Edit ${CONF_DIR}/unrealircd.conf and start the container again."
    exit 1
fi

# Generate a per-container self-signed certificate on first boot only.
# Never bake a shared private key into the image.
if { [ ! -f "${CONF_DIR}/tls/server.cert.pem" ] || [ ! -f "${CONF_DIR}/tls/server.key.pem" ]; } && \
   { [ ! -f "${CONF_DIR}/ssl/server.cert.pem" ] || [ ! -f "${CONF_DIR}/ssl/server.key.pem" ]; }; then
    echo "==> [INIT] Generating a self-signed TLS certificate..."
    printf 'Y\n\n\n\n\n\n\n' | su-exec "$USER_NAME:$GROUP_NAME" "$WORK_DIR/unrealircd" mkcert
fi

# Run the actual IRC daemon in the foreground so it is PID 1 and receives
# Docker stop signals directly. The wrapper script intentionally is not used
# for start/stop because it daemonizes the server.
echo "==> [START] Starting UnrealIRCd as ${USER_NAME}..."
exec su-exec "$USER_NAME:$GROUP_NAME" "$WORK_DIR/bin/unrealircd" -F

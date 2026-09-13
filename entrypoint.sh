#!/bin/sh
set -e

cleanup() {
    echo "==> [INFO] Stopping container..."
    echo "==> [INFO] Stopping UnrealIRCd..."

    su-exec ircd ./unrealircd stop || true

    echo "==> [INFO] UnrealIRCd stopped."
    exit 0
}

trap cleanup TERM INT

DEFAULTS_DIR="/home/ircd/unrealircd-defaults"
WORK_DIR="/home/ircd/unrealircd"
UUID_NAME="ircd"
GUID_NAME="ircd"

echo "==> [INIT] Folder checks..."

for dir in conf data cache tmp logs; do
    TARGET_DIR="$WORK_DIR/$dir"
    SOURCE_DIR="$DEFAULTS_DIR/$dir"

    chown -R "$UUID_NAME":"$GUID_NAME" "$TARGET_DIR"

    # 2. Specific logic by folder
    if [ "$dir" = "conf" ]; then
        # For configuration we should kill the process.
        if [ ! -f "$TARGET_DIR/unrealircd.conf" ]; then
            echo "==> [INFO] Fichier unrealircd.conf manquant. Copie de la configuration par défaut..."
            echo "==> [INFO] $SOURCE_DIR/. ==> $TARGET_DIR/"
            cp -Ra "$SOURCE_DIR/." "$TARGET_DIR/"

            echo "==> [ERROR] Please configure unrealircd.conf"
            exit 1
        fi
    else
        # For the rest we just copy.
        if [ -z "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; then
            echo "==> [INFO] Folder $dir empty. Starting the default structure copy..."
            echo "==> [INFO] $SOURCE_DIR/ ==> $TARGET_DIR/"
            cp -Ra "$SOURCE_DIR/." "$TARGET_DIR/" 2>/dev/null || true
        fi
    fi

    chown -R "${UUID_NAME}":"${GUID_NAME}" "${TARGET_DIR}"
    chmod -R u+rwX,go+rwX "${TARGET_DIR}"

    # everyone can write.
    find "${TARGET_DIR}" -type d -exec chmod 777 {} \;
    find "${TARGET_DIR}" -type f -exec chmod 666 {} \;
done

echo "==> [INFO] Starting UnrealIRCd as '$UUID_NAME'..."
cd /home/ircd/unrealircd

echo "=== BEFORE START ==="

set +e
su-exec ircd ./unrealircd start
RC=$?
set -e

if [ "${RC}" -ne 0 ]; then
    echo "==> [ERROR] UnrealIRCd crashed (code ${RC})"
    exit "${RC}"
fi

echo "=== AFTER START ==="
echo "RC=${RC}"

echo "==> [INFO] UnrealIRCd started"
su-exec ircd ./unrealircd status || true

echo "==> [INFO] PROCESS:"
ps aux | grep '[u]nrealircd' || true

echo "=== BEFORE WHILE LOOP ==="

# exec tail -f /dev/null
while true; do
    sleep 5
done

echo "=== AFTER WHILE LOOP ==="


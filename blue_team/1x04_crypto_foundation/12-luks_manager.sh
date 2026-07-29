#!/bin/bash
#
# 12-luks_manager.sh
# Creates, opens, or closes a LUKS-encrypted volume.
#
# Usage:
#   Create: sudo ./12-luks_manager.sh create <volume_file> <size_in_MB>
#   Open:   sudo ./12-luks_manager.sh open <volume_file> <mapper_name> <mount_point>
#   Close:  sudo ./12-luks_manager.sh close <mapper_name> <mount_point>
#
# Requires root (cryptsetup, mount, mkfs.ext4 all need it).

set -euo pipefail

usage() {
    echo "Usage:"
    echo "  Create: $0 create <volume_file> <size_in_MB>"
    echo "  Open:   $0 open <volume_file> <mapper_name> <mount_point>"
    echo "  Close:  $0 close <mapper_name> <mount_point>"
    exit 1
}

if [[ $EUID -ne 0 ]]; then
    echo "Error: this script must be run as root (sudo)."
    exit 1
fi

if [[ $# -lt 1 ]]; then
    usage
fi

MODE="$1"

case "$MODE" in
    create)
        if [[ $# -ne 3 ]]; then usage; fi
        VOLUME_FILE="$2"
        SIZE_MB="$3"

        if [[ -f "$VOLUME_FILE" ]]; then
            echo "Error: '$VOLUME_FILE' already exists. Refusing to overwrite."
            exit 1
        fi

        echo "[1/2] Creating ${SIZE_MB}MB volume file: $VOLUME_FILE"
        dd if=/dev/zero of="$VOLUME_FILE" bs=1M count="$SIZE_MB" status=progress

        echo "[2/2] Formatting with LUKS (you will be prompted for a passphrase)"
        cryptsetup luksFormat --batch-mode "$VOLUME_FILE"
        echo "Created and LUKS-formatted '$VOLUME_FILE'."
        ;;

    open)
        if [[ $# -ne 4 ]]; then usage; fi
        VOLUME_FILE="$2"
        MAPPER_NAME="$3"
        MOUNT_POINT="$4"

        if [[ ! -f "$VOLUME_FILE" ]]; then
            echo "Error: volume file '$VOLUME_FILE' not found."
            exit 1
        fi

        echo "[1/3] Opening LUKS volume (you will be prompted for the passphrase)"
        cryptsetup luksOpen "$VOLUME_FILE" "$MAPPER_NAME"

        # Only format with a filesystem the first time it's opened.
        if ! blkid "/dev/mapper/$MAPPER_NAME" >/dev/null 2>&1; then
            echo "[2/3] No filesystem detected — creating ext4"
            mkfs.ext4 -q "/dev/mapper/$MAPPER_NAME"
        else
            echo "[2/3] Existing filesystem detected — skipping mkfs"
        fi

        mkdir -p "$MOUNT_POINT"
        echo "[3/3] Mounting at $MOUNT_POINT"
        mount "/dev/mapper/$MAPPER_NAME" "$MOUNT_POINT"
        echo "Volume open and mounted at $MOUNT_POINT"
        ;;

    close)
        if [[ $# -ne 3 ]]; then usage; fi
        MAPPER_NAME="$2"
        MOUNT_POINT="$3"

        echo "[1/2] Unmounting $MOUNT_POINT"
        umount "$MOUNT_POINT"

        echo "[2/2] Closing LUKS mapping $MAPPER_NAME"
        cryptsetup luksClose "$MAPPER_NAME"
        echo "Volume unmounted and closed."
        ;;

    *)
        usage
        ;;
esac

#!/bin/bash
#
# 3-hash_verify.sh
# Verifies a file's integrity against an expected SHA-256 hash.
#
# Usage: ./3-hash_verify.sh <file_path> <expected_sha256_hash>

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <file_path> <expected_sha256_hash>"
    exit 1
fi

FILE_PATH="$1"
EXPECTED_HASH="$2"

if [[ ! -f "$FILE_PATH" ]]; then
    echo "Error: file '$FILE_PATH' not found."
    exit 1
fi

ACTUAL_HASH=$(sha256sum "$FILE_PATH" | awk '{print $1}')

# Case-insensitive comparison since hex hashes are often written in either case
if [[ "${ACTUAL_HASH,,}" == "${EXPECTED_HASH,,}" ]]; then
    echo "INTEGRITY OK"
    exit 0
else
    echo "INTEGRITY FAILED - expected $EXPECTED_HASH got $ACTUAL_HASH"
    exit 1
fi

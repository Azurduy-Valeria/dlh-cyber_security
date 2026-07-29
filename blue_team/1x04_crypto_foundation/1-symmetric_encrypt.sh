#!/bin/bash

set -euo pipefail

usage() {
    echo "Usage: $0 <input_file> <output_file> <cbc|gcm>"
    exit 1
}

if [[ $# -ne 3 ]]; then
    usage
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"
MODE="$3"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: input file '$INPUT_FILE' not found."
    exit 1
fi

if [[ "$MODE" != "cbc" && "$MODE" != "gcm" ]]; then
    echo "Error: mode must be 'cbc' or 'gcm'."
    usage
fi

read -rsp "Enter encryption passphrase: " PASSPHRASE
echo

case "$MODE" in
    cbc)
        # AES-256-CBC via openssl enc. -pbkdf2 forces a modern, slow key
        # derivation instead of OpenSSL's old (weak) default KDF.
        openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt \
            -in "$INPUT_FILE" -out "$OUTPUT_FILE" -pass "pass:$PASSPHRASE"
        echo "Encrypted '$INPUT_FILE' -> '$OUTPUT_FILE' (AES-256-CBC)"
        ;;
    gcm)
        # AES-256-GCM via Python's cryptography library, since
        # `openssl enc` cannot do AEAD ciphers on this system.
        if ! python3 -c "import cryptography" 2>/dev/null; then
            echo "Error: GCM mode requires Python's 'cryptography' package"
            echo "(pip install cryptography), because 'openssl enc' does"
            echo "not support AEAD ciphers on this system."
            exit 1
        fi
        PASSPHRASE="$PASSPHRASE" python3 - "$INPUT_FILE" "$OUTPUT_FILE" <<'PYEOF'
import os, sys
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

input_file, output_file = sys.argv[1], sys.argv[2]
password = os.environ["PASSPHRASE"].encode()

salt = os.urandom(16)
iv = os.urandom(12)
key = PBKDF2HMAC(algorithm=hashes.SHA256(), length=32, salt=salt,
                  iterations=600000).derive(password)

with open(input_file, "rb") as f:
    data = f.read()

encryptor = Cipher(algorithms.AES(key), modes.GCM(iv)).encryptor()
ciphertext = encryptor.update(data) + encryptor.finalize()

# Output layout: salt(16) || iv(12) || tag(16) || ciphertext
with open(output_file, "wb") as f:
    f.write(salt + iv + encryptor.tag + ciphertext)
PYEOF
        echo "Encrypted '$INPUT_FILE' -> '$OUTPUT_FILE' (AES-256-GCM)"
        ;;
esac

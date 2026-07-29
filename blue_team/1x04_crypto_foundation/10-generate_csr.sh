#!/bin/bash

set -euo pipefail

PREFIX="${1:-portal}"
KEY_FILE="${PREFIX}key.pem"
CSR_FILE="${PREFIX}.csr"
CONFIG_FILE="$(mktemp)"

# Generate the OpenSSL config inline so the script is self-contained.
cat > "$CONFIG_FILE" <<'EOF'
[ req ]
default_bits       = 256
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[ dn ]
CN = portal.meddefense.local
O  = MedDefense Health Systems
OU = Information Technology
L  = Central City
ST = State
C  = US

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = portal.meddefense.local
DNS.2 = portal.meddefense.com
DNS.3 = www.portal.meddefense.com
EOF

echo "[1/3] Generating ECC P-256 private key -> $KEY_FILE"
openssl ecparam -genkey -name prime256v1 -out "$KEY_FILE"
chmod 600 "$KEY_FILE"

echo "[2/3] Generating CSR -> $CSR_FILE"
openssl req -new -key "$KEY_FILE" -out "$CSR_FILE" -config "$CONFIG_FILE"

echo "[3/3] Inspecting CSR:"
openssl req -text -noout -in "$CSR_FILE"

rm -f "$CONFIG_FILE"
echo ""
echo "Done. Private key: $KEY_FILE (keep this secret). CSR ready to submit: $CSR_FILE"

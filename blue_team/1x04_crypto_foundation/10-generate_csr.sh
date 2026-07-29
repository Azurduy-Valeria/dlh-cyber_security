#!/bin/bash
#
# 10-generate_csr.sh
# Automates key generation and CSR creation for the MedDefense patient portal.
# Uses OpenSSL for both the private key (ECC P-256) and the CSR itself.
#
# Usage: ./10-generate_csr.sh
#   Produces: portalkey.pem (private key) and portal.csr (certificate request)

set -euo pipefail

KEY_FILE="portalkey.pem"
CSR_FILE="portal.csr"
CONFIG_FILE="$(mktemp)"

# OpenSSL config for the CSR: MedDefense identity fields + SAN entries,
# generated inline so the script is self-contained.
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

echo "[1/3] Generating ECC P-256 private key with OpenSSL -> portalkey.pem"
openssl ecparam -genkey -name prime256v1 -out portalkey.pem
chmod 600 portalkey.pem

echo "[2/3] Generating CSR with OpenSSL -> portal.csr"
openssl req -new -key portalkey.pem -out portal.csr -config "$CONFIG_FILE"

echo "[3/3] Inspecting CSR:"
openssl req -text -noout -in portal.csr

rm -f "$CONFIG_FILE"
echo ""
echo "Done. Private key: $KEY_FILE (keep this secret). CSR ready to submit: $CSR_FILE"

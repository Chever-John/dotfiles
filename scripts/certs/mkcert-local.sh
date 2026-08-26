#!/usr/bin/env bash
set -euo pipefail

CERT_DIR="${CERT_DIR:-/Users/minimax/Infra/softwares/certs}"
CERT_FILE="${CERT_DIR}/cheverjohn.mm.pem"
KEY_FILE="${CERT_DIR}/cheverjohn.mm-key.pem"
DOMAINS_CSV="${DOMAINS_CSV:-cheverjohn.mm,*.cheverjohn.mm,traefik.cheverjohn.mm,dh.cheverjohn.mm,netbox.cheverjohn.mm,sr-web.cheverjohn.mm}"

IFS=',' read -r -a DOMAINS <<< "${DOMAINS_CSV}"

mkdir -p "${CERT_DIR}"

if ! command -v mkcert >/dev/null 2>&1; then
  echo "mkcert not found. Install mkcert first." >&2
  exit 1
fi

mkcert -install

mkcert -cert-file "${CERT_FILE}" -key-file "${KEY_FILE}" "${DOMAINS[@]}"

echo "Certificate created:"
echo "  cert: ${CERT_FILE}"
echo "  key : ${KEY_FILE}"

scp /Users/minimax/Infra/softwares/certs/cheverjohn.mm*.pem \
    mmd:/home/CheverJohn/infra/softwares/Traefik/certs/


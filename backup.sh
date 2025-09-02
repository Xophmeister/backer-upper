#!/usr/bin/env bash

set -euo pipefail

readonly BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${BASE_DIR}/.configrc"

# Make SSH config
declare SSH_CONFIG="$(mktemp)"
trap 'rm -f "${SSH_CONFIG}"' EXIT

cat > "${SSH_CONFIG}" <<-EOF
Host backer-upper
  User ${REPO_USER}
  HostName ${REPO_HOST}
  Port ${REPO_PORT-22}
  PreferredAuthentications publickey
  IdentityFile ${BASE_DIR}/.secret-key
  IdentitiesOnly yes
  StrictHostKeyChecking no
  UserKnownHostsFile ${BASE_DIR}/.known-hosts
  ServerAliveInterval 60
  ServerAliveCountMax 3
  TCPKeepAlive yes
  Compression yes
  ConnectTimeout 30
  BatchMode yes
EOF

# Setup Borg repository connectivity
export BORG_REPO="ssh://backer-upper${REPO_PATH}/"
export BORG_RSH="ssh -F '${SSH_CONFIG}'"

# Borg archive ID
declare ARCHIVE="::{utcnow:%Y-%m-%d}"

# Create archive
echo "Starting backup of ${BACKUP_PATH}"
if ! borg list "${ARCHIVE}" >/dev/null 2>&1; then
  (
    cd "${BACKUP_PATH}"
    borg create \
      --verbose \
      --filter=AME \
      --stats \
      "${ARCHIVE}" \
      .
  )
else
  echo "Today's archive already exists; skipping"
fi

# Prune repository
echo "Starting archive pruning"
borg prune \
  --verbose \
  --list \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6

# Compact repository on Fridays
if [[ "$(date --utc +%u)" == "5" ]]; then
  echo "Compacting repository"
  borg compact --verbose
fi

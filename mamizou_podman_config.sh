#!/usr/bin/env bash
set -euo pipefail

echo "Copying quadlets..."
rm -rfv /etc/containers/systemd/*
cp -rv config/hosts/mamizou/podman/quadlets/* /etc/containers/systemd/

echo "Reloading systemctl daemon..."
systemctl daemon-reload

echo "Copying subuid/gid file..."
install -vm644 config/common/subuid /etc/subuid
install -vm644 config/common/subgid /etc/subgid

echo "Copying letsencrypt hooks..."
install -vm744 config/hosts/mamizou/letsencrypt/hooks/deploy/* /etc/letsencrypt/renewal-hooks/deploy/

echo "Copying kanidm config..."
install -vm640 -o100000 -g101000 config/hosts/mamizou/podman/config/kanidm/server.toml /var/lib/containers/storage/volumes/kanidm/
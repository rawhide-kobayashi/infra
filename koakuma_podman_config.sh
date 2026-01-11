#!/usr/bin/env bash
set -euo pipefail

echo "Copying quadlets..."
rm -rfv /etc/containers/systemd/*
cp -rv config/hosts/koakuma/podman/quadlets/* /etc/containers/systemd/

echo "Reloading systemctl daemon..."
systemctl daemon-reload

echo "Copying subuid/gid file..."
install -vm644 config/hosts/koakuma/subuid /etc/subuid
install -vm644 config/hosts/koakuma/subgid /etc/subgid

echo "Copying letsencrypt hooks..."
install -vm744 config/hosts/koakuma/letsencrypt/hooks/deploy/* /etc/letsencrypt/renewal-hooks/deploy/

echo "Copying kanidm config..."
install -vm644 config/hosts/koakuma/podman/config/kanidm/server.toml /var/lib/containers/storage/volumes/kanidm/
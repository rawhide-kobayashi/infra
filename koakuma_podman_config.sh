#!/usr/bin/env bash
set -euo pipefail

echo "Copying quadlets..."
rm -rfv /etc/containers/systemd/*
cp -rv config/hosts/koakuma/podman/quadlets/* /etc/containers/systemd/

echo "Reloading systemctl daemon..."
systemctl daemon-reload
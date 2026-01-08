#!/usr/bin/env bash
set -euo pipefail

echo "Copying quadlets..."
rm -rfv /etc/containers/systemd/*
install -vm644 config/hosts/koakuma/podman/systemd/* /etc/containers/systemd/

echo "Reloading systemctl daemon...
systemctl daemon-reload
#!/usr/bin/env bash
set -euo pipefail

install -vm640 -o100000 -g101000 /etc/letsencrypt/live/koakuma.idm.neetworks-auth.com/fullchain.pem /var/lib/containers/storage/volumes/kanidm/
install -vm640 -o100000 -g101000 /etc/letsencrypt/live/koakuma.idm.neetworks-auth.com/privkey.pem /var/lib/containers/storage/volumes/kanidm/
podman kill --signal SIGHUP kanidm-server
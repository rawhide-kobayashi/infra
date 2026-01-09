#!/usr/bin/env bash
set -euo pipefail

install -vm640 /etc/letsencrypt/live/koakuma.idm.neetworks-auth.com/fullchain.pem /var/lib/containers/storage/volumes/kanidm/
install -vm640 /etc/letsencrypt/live/koakuma.idm.neetworks-auth.com/privkey.pem /var/lib/containers/storage/volumes/kanidm/
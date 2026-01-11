#!/usr/bin/env bash
set -euo pipefail

install -vm400 -o101000 -g101000 /etc/letsencrypt/live/koakuma.idm.neetworks-auth.com/fullchain.pem /var/lib/containers/storage/volumes/kanidm/
install -vm400 -o101000 -g101000 /etc/letsencrypt/live/koakuma.idm.neetworks-auth.com/privkey.pem /var/lib/containers/storage/volumes/kanidm/
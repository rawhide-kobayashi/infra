#!/usr/bin/env bash
set -euo pipefail

install -vm640 /etc/letsencrypt/live/koakuma.idm.neetworks-auth.com/chain.pem /var/lib/containers/storage/volumes/kanidm/
install -vm640 /etc/letsencrypt/live/koakuma.idm.neetworks-auth.com/cert.pem /var/lib/containers/storage/volumes/kanidm/
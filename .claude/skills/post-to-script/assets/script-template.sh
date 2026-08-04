#!/usr/bin/env bash
#
# <ONE LINE: what this builds>
#
# Companion script for <post title> — <post url>
#
# Run this on:   <which machine, which user>
# Requires:      <commands/state it assumes already exist>
#
# Read it before you run it, and change the CONFIG block below to match your
# own network and names. It is safe to run more than once.

set -euo pipefail

# ---------------------------------------------------------------- CONFIG ----
# Every value here is one you are expected to change. Each can also be set as
# an environment variable, e.g.  CTID=123 ./setup.sh

CTID="${CTID:-100}"                        # <what this is>
CT_HOSTNAME="${CT_HOSTNAME:-media}"        # not HOSTNAME — bash already sets that
LXC_IP="${LXC_IP:-192.168.1.88/24}"        # static IP, must be free on your LAN
GATEWAY="${GATEWAY:-192.168.1.1}"          # your router
USERNAME="${USERNAME:-dylan}"              # non-root user created inside

# Secrets: fail fast rather than shipping a default.
: "${CT_PASSWORD:?set CT_PASSWORD before running, e.g. CT_PASSWORD=... ./setup.sh}"

# ---------------------------------------------------------------- HELPERS ---

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

# Steps that can't be scripted get collected here and printed at the end.
MANUAL_STEPS=()
note_manual() { MANUAL_STEPS+=("$1"); }

# Transports — one per execution context the post uses.
in_ct()   { pct exec "$CTID" -- bash -lc "$*"; }
as_user() { pct exec "$CTID" -- su - "$USERNAME" -c "$*"; }

preflight() {
  log "Preflight"
  [[ $EUID -eq 0 ]] || die "run as root on the Proxmox host"
  command -v pct >/dev/null || die "no pct — is this the Proxmox host?"
}

# ------------------------------------------------------------------ STEPS ---
# One function per section of the post, in the same order, named after the
# heading. Comment one out to skip it.

example_step() {
  log "Example step"

  # Idempotency: check before you change.
  if some_check; then
    warn "already done, skipping"
    return
  fi

  do_the_thing
}

# -------------------------------------------------------------------- RUN ---

main() {
  preflight
  example_step

  log "Done."
  if ((${#MANUAL_STEPS[@]})); then
    printf '\nStill to do by hand:\n'
    printf '  - %s\n' "${MANUAL_STEPS[@]}"
  fi
}

main "$@"

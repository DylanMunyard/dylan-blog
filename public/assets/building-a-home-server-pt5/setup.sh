#!/usr/bin/env bash
#
# Runs the apps from "Building a home media server - Part 5": clones the base
# image built in Part 4 twice, gives each clone its own IP and resources, mounts
# the ZFS pool into both, and brings up the *arr stack in one and the media
# server in the other.
#
# Run this on:   the Proxmox host, as root
# Requires:      the Part 4 base image (CT $BASE_CTID, template or stopped),
#                a ZFS pool mounted at $POOL (Part 3), internet access
#
# Read it before you run it. Change the CONFIG block to match your own network
# and names — the defaults are mine and the IPs almost certainly clash with
# something on your LAN. It is safe to run more than once.

set -euo pipefail

# ---------------------------------------------------------------- CONFIG ----
# Each of these can also be set as an environment variable, e.g.
#   ARRS_CTID=201 ARRS_IP=10.0.0.50/24 ./setup.sh

BASE_CTID="${BASE_CTID:-100}"                  # the Part 4 image to clone

ARRS_CTID="${ARRS_CTID:-101}"                  # *arrs + download clients
ARRS_IP="${ARRS_IP:-192.168.1.88/24}"
ARRS_MEMORY_MB="${ARRS_MEMORY_MB:-2048}"
ARRS_CORES="${ARRS_CORES:-2}"

MEDIA_CTID="${MEDIA_CTID:-102}"                # the media server
MEDIA_IP="${MEDIA_IP:-192.168.1.89/24}"
MEDIA_MEMORY_MB="${MEDIA_MEMORY_MB:-6144}"
MEDIA_CORES="${MEDIA_CORES:-4}"

GATEWAY="${GATEWAY:-192.168.1.1}"              # your router
BRIDGE="${BRIDGE:-vmbr0}"                      # Proxmox bridge on your LAN

USERNAME="${USERNAME:-dylan}"                  # the user Part 4 created
PUID="${PUID:-1000}"                           # UID the apps run as
PGID="${PGID:-1005}"                           # shared "mediaapps" GID
CT_TZ="${CT_TZ:-Australia/Brisbane}"           # container timezone

POOL="${POOL:-/media-tank}"                    # ZFS pool on the host (Part 3)
MOUNT="${MOUNT:-/media-data}"                  # where it appears in the LXCs

RENDER_NODE="${RENDER_NODE:-/dev/dri/renderD128}"  # Intel Quick Sync, Part 1

# Optional: grab one from https://www.plex.tv/claim just before running. It
# expires after four minutes. Without it the server comes up unclaimed and you
# link it through the web UI instead.
PLEX_CLAIM="${PLEX_CLAIM:-}"

# Secret: required up front rather than shipped with a default, so nobody ends
# up running a media stack with a password that's published on a blog.
: "${TRANSMISSION_PASS:?set TRANSMISSION_PASS before running (Transmission web UI login)}"

# --------------------------------------------------------------- HELPERS ----

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m xx\033[0m %s\n' "$*" >&2; exit 1; }

MANUAL_STEPS=()
note_manual() { MANUAL_STEPS+=("$1"); }

# Run a block of bash inside a container. Pushing a file rather than building
# one giant `pct exec` string keeps heredocs and $(...) evaluating in the
# container's shell instead of this one.
in_ct() {
  local ctid="$1" tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  pct push "$ctid" "$tmp" /tmp/step.sh --perms 700 >/dev/null
  rm -f "$tmp"
  pct exec "$ctid" -- bash /tmp/step.sh
  pct exec "$ctid" -- rm -f /tmp/step.sh
}

preflight() {
  log "Preflight"
  [[ $EUID -eq 0 ]] || die "run this as root on the Proxmox host"
  command -v pct >/dev/null || die "no pct — this doesn't look like a Proxmox host"
  [[ -d "$POOL" ]] || die "$POOL does not exist — set up the ZFS pool from Part 3 first"
  pct status "$BASE_CTID" &>/dev/null \
    || die "CT $BASE_CTID doesn't exist — build the base image from Part 4 first"
  echo "    host ok, pool $POOL present, base image $BASE_CTID found"
}

# ------------------------------------------------------------------ STEPS ---

# Post: "Clone the image". The clone inherits the base image's IP, so the pct
# set immediately after is not optional — two machines on one address otherwise.
clone_ct() {
  local ctid="$1" hostname="$2" ip="$3" memory="$4" cores="$5"

  if pct status "$ctid" &>/dev/null; then
    echo "    CT $ctid already exists, leaving it alone"
  else
    log "Cloning $BASE_CTID -> $ctid ($hostname)"
    pct clone "$BASE_CTID" "$ctid" --hostname "$hostname" --full 1
  fi

  pct set "$ctid" \
    --net0 "name=eth0,bridge=${BRIDGE},ip=${ip},gw=${GATEWAY}" \
    --memory "$memory" \
    --cores "$cores" \
    --onboot 1
}

# Post: "Check the ID map came across". The clone copies the config file, but
# rather than trust that, assert the block on each clone — it's the same
# idempotent write as Part 4 and it costs nothing when it's already right.
assert_idmap() {
  local ctid="$1" conf="/etc/pve/lxc/${ctid}.conf"

  local block
  block="$(cat <<EOF
lxc.idmap: u 0 100000 ${PUID}
lxc.idmap: u ${PUID} ${PUID} 1
lxc.idmap: u $((PUID + 1)) $((100000 + PUID + 1)) $((65536 - PUID - 1))
lxc.idmap: g 0 100000 ${PGID}
lxc.idmap: g ${PGID} ${PGID} 1
lxc.idmap: g $((PGID + 1)) $((100000 + PGID + 1)) $((65536 - PGID - 1))
EOF
)"

  # Already correct? Leave the file alone rather than stopping a running
  # container to rewrite bytes that already match.
  if [[ "$(grep '^lxc\.idmap:' "$conf" || true)" == "$block" ]]; then
    echo "    CT $ctid idmap ok"
  else
    log "Rewriting idmap on CT $ctid"
    pct stop "$ctid" 2>/dev/null || true
    # /etc/pve is pmxcfs — `sed -i` renames a temp file over the original and
    # that doesn't fly here. Filter to /tmp, then write the original in place.
    local tmp; tmp="$(mktemp)"
    grep -v '^lxc\.idmap:' "$conf" > "$tmp"
    printf '%s\n' "$block" >> "$tmp"
    cat "$tmp" > "$conf"
    rm -f "$tmp"
  fi

  grep -q '^features:.*nesting=1' "$conf" || pct set "$ctid" --features nesting=1,keyctl=1
}

# Post: "Mount the ZFS pool"
mount_pool() {
  local ctid="$1"
  log "Mounting $POOL into CT $ctid at $MOUNT"
  pct set "$ctid" --mp0 "${POOL},mp=${MOUNT}"
}

# Post: "Mount the ZFS pool", the chgrp/chmod pair. This one runs on the HOST,
# not in an LXC: the top of the pool belongs to the host's root user and an
# unprivileged container can't chgrp it. Numeric GID, because the mediaapps
# name only exists inside the containers.
own_pool_on_host() {
  log "Handing $POOL to group $PGID (on the host)"
  chgrp -R "$PGID" "$POOL"
  # The leading 2 is the setgid bit: without it new files get the creating
  # container's primary group instead of mediaapps.
  chmod -R 2775 "$POOL"
}

# Post: "Pass the GPU through". dev0 is Proxmox's device passthrough; gid=PGID
# means the node lands inside the container owned by mediaapps, which is the
# group the media server runs as.
pass_through_gpu() {
  local ctid="$1"
  if [[ ! -e "$RENDER_NODE" ]]; then
    warn "$RENDER_NODE not present on the host — skipping GPU passthrough"
    note_manual "No render node at $RENDER_NODE on the host, so the media server will transcode on CPU. Check 'ls -l /dev/dri' and set RENDER_NODE."
    return
  fi
  log "Passing $RENDER_NODE through to CT $ctid"
  pct set "$ctid" --dev0 "${RENDER_NODE},gid=${PGID},mode=0660"
}

start_ct() {
  local ctid="$1"
  log "Starting CT $ctid"
  pct status "$ctid" | grep -q running || pct start "$ctid"

  for _ in $(seq 1 30); do
    pct exec "$ctid" -- test -e /etc/os-release &>/dev/null && break
    sleep 1
  done

  pct exec "$ctid" -- test -d "$MOUNT" \
    || die "$MOUNT not mounted inside CT $ctid — check the mp0 line in its conf"

  # An unmapped container shows the pool as nobody/nogroup, and every app would
  # fail to write. Catch it here rather than three web UIs later.
  local owner
  owner="$(pct exec "$ctid" -- stat -c '%U:%G' "$MOUNT")"
  case "$owner" in
    nobody:*|*:nogroup)
      die "$MOUNT is owned by $owner inside CT $ctid — the idmap isn't taking effect" ;;
    *) echo "    $MOUNT owned by $owner" ;;
  esac
}

# Substituted with bash expansion rather than sed, because a password is allowed
# to contain the characters sed would treat as delimiters. The replacements are
# quoted because bash 5.2+ expands a bare & in a substitution to the text that
# matched, which would eat a password like "a&b".
push_compose() {
  local ctid="$1" file="$2"

  local body; body="$(cat "$file")"
  body="${body//__PUID__/"$PUID"}"
  body="${body//__PGID__/"$PGID"}"
  body="${body//__TZ__/"$CT_TZ"}"
  body="${body//__MOUNT__/"$MOUNT"}"
  body="${body//__TRANSMISSION_PASS__/"$TRANSMISSION_PASS"}"
  body="${body//__PLEX_CLAIM__/"$PLEX_CLAIM"}"
  printf '%s\n' "$body" > "$file"

  pct push "$ctid" "$file" "/home/${USERNAME}/compose.yaml" --perms 600 >/dev/null
  rm -f "$file"
  pct exec "$ctid" -- chown "${USERNAME}:${USERNAME}" "/home/${USERNAME}/compose.yaml"
}

bring_up_stack() {
  local ctid="$1"
  log "Bringing up the stack in CT $ctid"
  in_ct "$ctid" <<EOF
set -euo pipefail
su - "${USERNAME}" -c 'cd ~ && docker compose up -d'
EOF
}

# Post: "The *arrs"
write_arrs_compose() {
  log "Writing compose.yaml for the *arrs"

  local compose; compose="$(mktemp)"
  # Quoted marker: nothing in here is expanded by the host shell, so the
  # placeholders survive intact for push_compose to substitute.
  cat > "$compose" <<'YAML'
services:
  jackett:
    image: lscr.io/linuxserver/jackett:latest
    container_name: jackett
    environment:
      - PUID=__PUID__
      - PGID=__PGID__
      - UMASK=002
      - TZ=__TZ__
    volumes:
      - __MOUNT__/config-jackett:/config
      - __MOUNT__:/data
    ports:
      - 9117:9117
    restart: unless-stopped
    networks:
      - arrs
  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=__PUID__
      - PGID=__PGID__
      - UMASK=002
      - TZ=__TZ__
    volumes:
      - __MOUNT__/config-sonarr:/config
      - __MOUNT__:/data
    ports:
      - 8989:8989
    restart: unless-stopped
    networks:
      - arrs
  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=__PUID__
      - PGID=__PGID__
      - UMASK=002
      - TZ=__TZ__
    volumes:
      - __MOUNT__/config-radarr:/config
      - __MOUNT__:/data
    ports:
      - 7878:7878
    restart: unless-stopped
    networks:
      - arrs
  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:latest
    container_name: sabnzbd
    environment:
      - PUID=__PUID__
      - PGID=__PGID__
      - UMASK=002
      - TZ=__TZ__
    volumes:
      - __MOUNT__/config-sabnzbd:/config
      - __MOUNT__:/data
    ports:
      - 8080:8080
    restart: unless-stopped
    networks:
      - arrs
  transmission:
    image: lscr.io/linuxserver/transmission:latest
    container_name: transmission
    environment:
      - PUID=__PUID__
      - PGID=__PGID__
      - UMASK=002
      - TZ=__TZ__
      - USER=admin
      - PASS=__TRANSMISSION_PASS__
    volumes:
      - __MOUNT__/config-transmission:/config
      - __MOUNT__:/data
    ports:
      - 9091:9091
      - 51413:51413
      - 51413:51413/udp
    restart: unless-stopped
    networks:
      - arrs
  unpackerr:
    image: golift/unpackerr
    volumes:
      - __MOUNT__:/data
    user: __PUID__:__PGID__
    environment:
      - TZ=__TZ__
      - UN_QUIET=false
      - UN_DEBUG=false
      - UN_ERROR_STDERR=false
      - UN_LOG_QUEUES=1m
      - UN_LOG_FILES=10
      - UN_LOG_FILE_MB=10
      - UN_INTERVAL=2m
      - UN_START_DELAY=1m
      - UN_RETRY_DELAY=5m
      - UN_MAX_RETRIES=3
      - UN_PARALLEL=1
      - UN_FILE_MODE=0644
      - UN_DIR_MODE=0755
      - UN_ACTIVITY=false
      - UN_SONARR_0_URL=http://sonarr:8989
      - UN_SONARR_0_API_KEY=PUT-SONARR-API-KEY-HERE
      - UN_RADARR_0_URL=http://radarr:7878
      - UN_RADARR_0_API_KEY=PUT-RADARR-API-KEY-HERE
    restart: unless-stopped
    networks:
      - arrs
networks:
  arrs: null
YAML

  # The API keys stay as placeholders on purpose — Sonarr and Radarr don't mint
  # them until they've started. See the manual steps at the end.
  note_manual "Unpackerr: copy the API keys from Sonarr and Radarr (Settings > General > API Key) into UN_SONARR_0_API_KEY / UN_RADARR_0_API_KEY in ~${USERNAME}/compose.yaml on CT ${ARRS_CTID}, then re-run 'docker compose up -d'. It restart-loops until they're valid."

  push_compose "$ARRS_CTID" "$compose"
}

# Post: "The media server". network_mode: host because Plex finds clients by
# broadcast, which doesn't survive being NATed through Docker's bridge.
write_media_compose() {
  log "Writing compose.yaml for the media server"

  local compose; compose="$(mktemp)"
  cat > "$compose" <<'YAML'
services:
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    network_mode: host
    environment:
      - PUID=__PUID__
      - PGID=__PGID__
      - UMASK=002
      - TZ=__TZ__
      - VERSION=docker
      - PLEX_CLAIM=__PLEX_CLAIM__
    devices:
      - /dev/dri:/dev/dri
    volumes:
      - __MOUNT__/config-plex:/config
      - __MOUNT__:/data
    restart: unless-stopped
YAML

  # No render node means no /dev/dri inside the LXC, and the devices: line would
  # stop the container from starting at all. Drop it and transcode on CPU.
  if ! pct exec "$MEDIA_CTID" -- test -e /dev/dri 2>/dev/null; then
    grep -v -e 'devices:' -e '/dev/dri:/dev/dri' "$compose" > "${compose}.tmp"
    mv "${compose}.tmp" "$compose"
  fi

  if [[ -z "$PLEX_CLAIM" ]]; then
    note_manual "No PLEX_CLAIM set, so the server came up unclaimed. Open http://${MEDIA_IP%%/*}:32400/web and sign in to link it, or get a token from https://www.plex.tv/claim (valid 4 minutes) and re-run."
  fi

  push_compose "$MEDIA_CTID" "$compose"
}

# -------------------------------------------------------------------- RUN ---

main() {
  preflight
  own_pool_on_host

  # --- the *arrs ---
  clone_ct "$ARRS_CTID" arrs "$ARRS_IP" "$ARRS_MEMORY_MB" "$ARRS_CORES"
  assert_idmap "$ARRS_CTID"
  mount_pool "$ARRS_CTID"
  start_ct "$ARRS_CTID"
  write_arrs_compose
  bring_up_stack "$ARRS_CTID"

  # --- the media server ---
  clone_ct "$MEDIA_CTID" media "$MEDIA_IP" "$MEDIA_MEMORY_MB" "$MEDIA_CORES"
  assert_idmap "$MEDIA_CTID"
  mount_pool "$MEDIA_CTID"
  pass_through_gpu "$MEDIA_CTID"
  start_ct "$MEDIA_CTID"
  write_media_compose
  bring_up_stack "$MEDIA_CTID"

  # Post: "Point the apps at the right paths" — these are first-run settings in
  # each app's own web UI, with no CLI to drive them.
  local arrs_ip="${ARRS_IP%%/*}" media_ip="${MEDIA_IP%%/*}"
  note_manual "Sonarr (http://${arrs_ip}:8989) > Media Management > Root Folder = /data/tv"
  note_manual "Radarr (http://${arrs_ip}:7878) > Media Management > Root Folder = /data/movies"
  note_manual "SABnzbd (http://${arrs_ip}:8080) > Folders > Temporary Download Folder = /data/downloads/incomplete, Completed = /data/downloads/complete"
  note_manual "Transmission (http://${arrs_ip}:9091, log in as admin) > Edit Preferences > Download to = /data/downloads, and untick 'Use temporary folder'"
  note_manual "Jackett (http://${arrs_ip}:9117) > add your indexers, then add Jackett to Sonarr/Radarr"
  note_manual "Plex (http://${media_ip}:32400/web) > add libraries: Movies = /data/movies, TV Shows = /data/tv"
  note_manual "Plex > Settings > Transcoder > tick 'Use hardware acceleration when available', then check a transcode session shows (hw) on the dashboard"

  log "Done."
  printf '\n*arrs:        %s\nmedia server: %s\n' "$arrs_ip" "$media_ip"

  if ((${#MANUAL_STEPS[@]})); then
    printf '\nStill to do by hand (each app configures itself through its own web UI):\n'
    printf '  - %s\n' "${MANUAL_STEPS[@]}"
    printf '\n'
  fi
}

main "$@"

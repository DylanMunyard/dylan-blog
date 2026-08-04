#!/usr/bin/env bash
#
# Builds the media server LXC from "Building a home media server - Part 4":
# creates an unprivileged Debian container on Proxmox, gives it a static IP,
# maps the user IDs, mounts the ZFS pool, installs Docker inside it, and brings
# up the *arr / download stack with docker compose.
#
# Run this on:   the Proxmox host, as root
# Requires:      a ZFS pool already mounted at $POOL (Part 3), internet access
#
# Read it before you run it. Change the CONFIG block to match your own network
# and names — the defaults are mine and the IP almost certainly clashes with
# something on your LAN. It is safe to run more than once.

set -euo pipefail

# ---------------------------------------------------------------- CONFIG ----
# Each of these can also be set as an environment variable, e.g.
#   CTID=123 LXC_IP=10.0.0.50/24 ./setup.sh

CTID="${CTID:-100}"                            # container ID, must be unused
CT_HOSTNAME="${CT_HOSTNAME:-media}"            # not HOSTNAME — bash sets that
LXC_IP="${LXC_IP:-192.168.1.88/24}"            # static IP, free on your LAN
GATEWAY="${GATEWAY:-192.168.1.1}"              # your router
BRIDGE="${BRIDGE:-vmbr0}"                      # Proxmox bridge on your LAN
STORAGE="${STORAGE:-local-lvm}"                # rootfs storage (`pvesm status`)
DISK_GB="${DISK_GB:-16}"                       # rootfs size
MEMORY_MB="${MEMORY_MB:-6144}"                 # RAM the LXC sees
CORES="${CORES:-4}"                            # CPU cores the LXC sees

USERNAME="${USERNAME:-dylan}"                  # non-root user inside the LXC
PUID="${PUID:-1000}"                           # UID the apps run as
PGID="${PGID:-1005}"                           # shared "mediaapps" GID
CT_TZ="${CT_TZ:-Australia/Brisbane}"           # container timezone

POOL="${POOL:-/media-tank}"                    # ZFS pool on the host (Part 3)
MOUNT="${MOUNT:-/media-data}"                  # where it appears in the LXC

# Secrets: required up front rather than shipped with a default, so nobody
# ends up running a media stack with a password that's published on a blog.
: "${CT_PASSWORD:?set CT_PASSWORD before running, e.g. CT_PASSWORD='...' ./setup.sh}"
: "${TRANSMISSION_PASS:?set TRANSMISSION_PASS before running (Transmission web UI login)}"

# --------------------------------------------------------------- HELPERS ----

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m xx\033[0m %s\n' "$*" >&2; exit 1; }

MANUAL_STEPS=()
note_manual() { MANUAL_STEPS+=("$1"); }

CONF="/etc/pve/lxc/${CTID}.conf"
TEMPLATE=""   # resolved by download_template

# Run a block of bash inside the container. Pushing a file rather than building
# one giant `pct exec` string keeps heredocs and $(...) evaluating in the
# container's shell instead of this one.
in_ct() {
  local tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  pct push "$CTID" "$tmp" /tmp/step.sh --perms 700 >/dev/null
  rm -f "$tmp"
  pct exec "$CTID" -- bash /tmp/step.sh
  pct exec "$CTID" -- rm -f /tmp/step.sh
}

preflight() {
  log "Preflight"
  [[ $EUID -eq 0 ]] || die "run this as root on the Proxmox host"
  command -v pct    >/dev/null || die "no pct — this doesn't look like a Proxmox host"
  command -v pveam  >/dev/null || die "no pveam — this doesn't look like a Proxmox host"
  [[ -d "$POOL" ]] || die "$POOL does not exist — set up the ZFS pool from Part 3 first"
  echo "    host ok, pool $POOL present"
}

# ------------------------------------------------------------------ STEPS ---

# Post: "Download a template"
download_template() {
  log "Downloading a Debian template"
  pveam update >/dev/null

  # The post pins debian-12-standard_12.12-1; resolve the newest 12.x instead so
  # this keeps working after Proxmox rotates the file out of the mirror.
  TEMPLATE="$(pveam available --section system \
    | awk '{print $2}' | grep '^debian-12-standard' | sort -V | tail -1)"
  [[ -n "$TEMPLATE" ]] || die "no debian-12-standard template offered by the mirror"

  if pveam list local 2>/dev/null | grep -q "$TEMPLATE"; then
    echo "    $TEMPLATE already downloaded"
  else
    pveam download local "$TEMPLATE"
  fi
}

# Post: "Deploy LXC" (the Create CT wizard) + "Give your LXC a static IP"
# (the Network > Edit screen). Both wizards are just these flags.
create_container() {
  log "Creating container $CTID"

  if pct status "$CTID" &>/dev/null; then
    echo "    CT $CTID already exists, leaving it alone"
    return
  fi

  # --unprivileged 1 is the wizard's checked-by-default box.
  # --features is set here rather than hand-edited into the conf file later,
  #   which sidesteps the post's warning about `features:` appearing twice.
  pct create "$CTID" "local:vztmpl/${TEMPLATE}" \
    --hostname "$CT_HOSTNAME" \
    --unprivileged 1 \
    --features nesting=1,keyctl=1 \
    --cores "$CORES" \
    --memory "$MEMORY_MB" \
    --rootfs "${STORAGE}:${DISK_GB}" \
    --net0 "name=eth0,bridge=${BRIDGE},ip=${LXC_IP},gw=${GATEWAY}" \
    --mp0 "${POOL},mp=${MOUNT}" \
    --onboot 1
}

# Post: "Enable nesting, map the user IDs, mount the ZFS pool"
map_user_ids() {
  log "Mapping user IDs"

  # Let root hand out the two IDs the apps actually use.
  grep -qxF "root:${PUID}:1" /etc/subuid || echo "root:${PUID}:1" >> /etc/subuid
  grep -qxF "root:${PGID}:1" /etc/subgid || echo "root:${PGID}:1" >> /etc/subgid

  # The idmap lines have no pct flag, so they go into the conf file. Each range
  # reads: starting at this ID inside, map to this ID on the host, this many.
  # The three ranges per type have to add up to 65536 or the LXC won't start.
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

  pct stop "$CTID" 2>/dev/null || true

  # Drop every existing idmap line before appending, so a second run replaces
  # the block instead of doubling it — a duplicate "u 0" mapping makes the
  # container refuse to start.
  #
  # Don't be tempted to wrap this in "# >>> managed block" comment markers and
  # delete between them: Proxmox treats '#' lines as the container's description
  # field, hoists them to the top of the file and URL-encodes non-ASCII in them.
  # The markers end up separated from the lines they were meant to delimit.
  # Matching on 'lxc.idmap:' itself is unambiguous and survives that rewrite.
  #
  # /etc/pve is pmxcfs, not a normal filesystem — `sed -i` renames a temp file
  # over the original and that doesn't fly here. Filter to /tmp, then truncate
  # and write the original in place.
  local tmp; tmp="$(mktemp)"
  grep -v '^lxc\.idmap:' "$CONF" > "$tmp"
  printf '%s\n' "$block" >> "$tmp"
  cat "$tmp" > "$CONF"
  rm -f "$tmp"

  echo "    idmap block written to $CONF"
}

start_container() {
  log "Starting container"
  pct status "$CTID" | grep -q running || pct start "$CTID"

  # Wait for networking before anything tries to apt-get.
  for _ in $(seq 1 30); do
    pct exec "$CTID" -- test -e /etc/os-release &>/dev/null && break
    sleep 1
  done

  # Set root's password here rather than passing --password to pct create,
  # which would leave it visible in the host's process list.
  echo "root:${CT_PASSWORD}" | pct exec "$CTID" -- chpasswd
}

# Post: "Create a non-root user"
create_user() {
  log "Creating non-root user $USERNAME"
  in_ct <<EOF
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
# sudo before usermod: the 'sudo' group is created by the package, so adding a
# user to it first would fail on a fresh Debian template.
apt-get install -y -qq sudo ca-certificates curl
if id -u "${USERNAME}" &>/dev/null; then
  echo "    ${USERNAME} already exists"
else
  adduser --disabled-password --gecos "" "${USERNAME}"
fi
usermod -aG sudo "${USERNAME}"
EOF

  # Set the password over stdin instead of interpolating it into the script
  # above — a password containing $ or a backtick would otherwise be evaluated
  # as shell inside the container.
  echo "${USERNAME}:${CT_PASSWORD}" | pct exec "$CTID" -- chpasswd
}

# Post: "Install Docker" + the linux-postinstall steps
install_docker() {
  log "Installing Docker"
  in_ct <<EOF
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.asc ]; then
  curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
fi

# \$VERSION_CODENAME and dpkg --print-architecture are escaped so they resolve
# in here, against the container's own Debian release and arch.
tee /etc/apt/sources.list.d/docker.sources >/dev/null <<SOURCES
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: \$(. /etc/os-release && echo "\$VERSION_CODENAME")
Components: stable
Architectures: \$(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
SOURCES

apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

# The post's "sudo docker run hello-world" fails with permission denied until
# the user is in the docker group. Do that first, then verify.
getent group docker >/dev/null || groupadd docker
usermod -aG docker "${USERNAME}"

# su - starts a fresh session, so the new group membership is already in effect
# and this stands in for the post's "log out and back in again".
su - "${USERNAME}" -c 'docker run --rm hello-world' >/dev/null
echo "    docker works as ${USERNAME}"
EOF
}

# Post: "Set up a shared group for file permissions" (steps 1 and 2)
create_shared_group() {
  log "Creating shared group for file permissions"
  in_ct <<EOF
set -euo pipefail
getent group ${PGID} >/dev/null || groupadd -g ${PGID} mediaapps
usermod -aG mediaapps "${USERNAME}"
EOF
}

# Post: "Set up a shared group for file permissions" step 3 — this one runs on
# the HOST, not in the LXC. The top of the pool belongs to the host's root user
# and an unprivileged container can't chgrp it. Numeric GID, because the
# mediaapps name only exists inside the container.
own_pool_on_host() {
  log "Handing $POOL to group $PGID (on the host)"
  chgrp -R "$PGID" "$POOL"
  # The leading 2 is the setgid bit: without it new files get the creating
  # container's primary group instead of mediaapps.
  chmod -R 2775 "$POOL"
}

# The post reboots here, because it edits the conf file on a container that's
# already running. This script writes the idmap before the first start, so the
# map is live from boot one and there's nothing to reboot into — all that's
# left is to check the pool actually came through.
verify_mount() {
  log "Checking the pool is mounted inside the LXC"
  pct exec "$CTID" -- test -d "$MOUNT" \
    || die "$MOUNT not mounted inside the LXC — check the mp0 line in $CONF"
  echo "    $MOUNT present"
}

# Post: "Docker Compose"
write_compose() {
  log "Writing compose.yaml"

  local compose; compose="$(mktemp)"
  # Quoted marker: nothing in here is expanded by the host shell, so the
  # container's own values survive intact.
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

  # Substituted with bash expansion rather than sed, because a password is
  # allowed to contain the characters sed would treat as delimiters. The
  # replacements are quoted because bash 5.2+ expands a bare & in a
  # substitution to the text that matched, which would eat a password like
  # "a&b".
  local body; body="$(cat "$compose")"
  body="${body//__PUID__/"$PUID"}"
  body="${body//__PGID__/"$PGID"}"
  body="${body//__TZ__/"$CT_TZ"}"
  body="${body//__MOUNT__/"$MOUNT"}"
  body="${body//__TRANSMISSION_PASS__/"$TRANSMISSION_PASS"}"
  printf '%s\n' "$body" > "$compose"

  # The API keys stay as placeholders on purpose — Sonarr and Radarr don't mint
  # them until they've started. See the manual steps at the end.
  note_manual "Unpackerr: copy the API keys from Sonarr and Radarr (Settings > General > API Key) into UN_SONARR_0_API_KEY / UN_RADARR_0_API_KEY in ~${USERNAME}/compose.yaml, then re-run 'docker compose up -d'. It restart-loops until they're valid."

  pct push "$CTID" "$compose" "/home/${USERNAME}/compose.yaml" --perms 600 >/dev/null
  rm -f "$compose"
  pct exec "$CTID" -- chown "${USERNAME}:${USERNAME}" "/home/${USERNAME}/compose.yaml"
}

bring_up_stack() {
  log "Bringing up the stack"
  in_ct <<EOF
set -euo pipefail
su - "${USERNAME}" -c 'cd ~ && docker compose up -d'
EOF

  # Post: "Point the apps at the right paths" — these are first-run settings in
  # each app's own web UI, with no CLI to drive them.
  local ip="${LXC_IP%%/*}"
  note_manual "Sonarr (http://${ip}:8989) > Media Management > Root Folder = /data/tv"
  note_manual "Radarr (http://${ip}:7878) > Media Management > Root Folder = /data/movies"
  note_manual "SABnzbd (http://${ip}:8080) > Folders > Temporary Download Folder = /data/downloads/incomplete, Completed = /data/downloads/complete"
  note_manual "Transmission (http://${ip}:9091, log in as admin) > Edit Preferences > Download to = /data/downloads, and untick 'Use temporary folder'"
  note_manual "Jackett (http://${ip}:9117) > add your indexers, then add Jackett to Sonarr/Radarr"
}

# -------------------------------------------------------------------- RUN ---

main() {
  preflight
  download_template
  create_container
  map_user_ids
  start_container
  verify_mount
  create_user
  install_docker
  create_shared_group
  own_pool_on_host
  write_compose
  bring_up_stack

  log "Done."
  printf '\nLXC %s is up at %s\n' "$CTID" "${LXC_IP%%/*}"

  if ((${#MANUAL_STEPS[@]})); then
    printf '\nStill to do by hand (each app configures itself through its own web UI):\n'
    printf '  - %s\n' "${MANUAL_STEPS[@]}"
    printf '\n'
  fi
}

main "$@"

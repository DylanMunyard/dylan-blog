#!/usr/bin/env bash
#
# Builds the base LXC image from "Building a home media server - Part 4":
# creates an unprivileged Debian container on Proxmox, gives it a static IP,
# maps the user IDs, installs Docker inside it, creates the shared group, and
# converts it to a template ready to clone.
#
# Nothing media-specific goes in here — no pool mount, no apps. That's Part 5,
# and its script (assets/building-a-home-server-pt5/setup.sh) clones what this
# one produces.
#
# Run this on:   the Proxmox host, as root
# Requires:      internet access
#
# Read it before you run it. Change the CONFIG block to match your own network
# and names — the defaults are mine and the IP almost certainly clashes with
# something on your LAN. It is safe to run more than once.

set -euo pipefail

# ---------------------------------------------------------------- CONFIG ----
# Each of these can also be set as an environment variable, e.g.
#   CTID=123 LXC_IP=10.0.0.50/24 ./setup.sh

CTID="${CTID:-100}"                            # container ID, must be unused
CT_HOSTNAME="${CT_HOSTNAME:-base}"             # not HOSTNAME — bash sets that
LXC_IP="${LXC_IP:-192.168.1.88/24}"            # static IP, free on your LAN
GATEWAY="${GATEWAY:-192.168.1.1}"              # your router
BRIDGE="${BRIDGE:-vmbr0}"                      # Proxmox bridge on your LAN
STORAGE="${STORAGE:-local-lvm}"                # rootfs storage (`pvesm status`)
DISK_GB="${DISK_GB:-16}"                       # rootfs size
MEMORY_MB="${MEMORY_MB:-2048}"                 # RAM the image sees; clones
CORES="${CORES:-2}"                            #   get their own in Part 5

USERNAME="${USERNAME:-dylan}"                  # non-root user inside the LXC
PUID="${PUID:-1000}"                           # UID the apps run as
PGID="${PGID:-1005}"                           # shared "mediaapps" GID

# pct template is one-way: the container can never be started again, only
# cloned. Set MAKE_TEMPLATE=0 to leave it as a normal stopped container — Part 5
# can clone either.
MAKE_TEMPLATE="${MAKE_TEMPLATE:-1}"

# Secret: required up front rather than shipped with a default, so nobody ends
# up running a container with a password that's published on a blog.
: "${CT_PASSWORD:?set CT_PASSWORD before running, e.g. CT_PASSWORD='...' ./setup.sh}"

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

  # Already converted? Everything below would fail on a template, and there's
  # nothing left to do to it anyway.
  if [[ -f "$CONF" ]] && grep -qx 'template: 1' "$CONF"; then
    log "CT $CTID is already a template — nothing to do"
    printf '\nClone it with:\n  pct clone %s 101 --hostname arrs --full 1\n\n' "$CTID"
    exit 0
  fi
  echo "    host ok"
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
  # No --mp0: the pool gets mounted per-clone in Part 5, not baked into the
  #   image.
  pct create "$CTID" "local:vztmpl/${TEMPLATE}" \
    --hostname "$CT_HOSTNAME" \
    --unprivileged 1 \
    --features nesting=1,keyctl=1 \
    --cores "$CORES" \
    --memory "$MEMORY_MB" \
    --rootfs "${STORAGE}:${DISK_GB}" \
    --net0 "name=eth0,bridge=${BRIDGE},ip=${LXC_IP},gw=${GATEWAY}" \
    --onboot 1
}

# Post: "Enable nesting and map the user IDs"
map_user_ids() {
  log "Mapping user IDs"

  # Let root hand out the two IDs the apps actually use. These live on the host,
  # so they're done once here and every clone inherits the effect.
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
docker rmi -f hello-world >/dev/null 2>&1 || true
echo "    docker works as ${USERNAME}"
EOF
}

# Post: "Set up a shared group for file permissions"
create_shared_group() {
  log "Creating shared group for file permissions"
  in_ct <<EOF
set -euo pipefail
getent group ${PGID} >/dev/null || groupadd -g ${PGID} mediaapps
usermod -aG mediaapps "${USERNAME}"
EOF
}

# Post: "Turn it into a template"
make_template() {
  log "Cleaning up and shutting down"
  in_ct <<'EOF'
set -euo pipefail
apt-get clean
# Empty, not deleted: systemd writes a fresh ID into it on each clone's first
# boot, but only if the file exists.
truncate -s 0 /etc/machine-id
EOF

  pct shutdown "$CTID"
  for _ in $(seq 1 60); do
    pct status "$CTID" | grep -q stopped && break
    sleep 1
  done

  if [[ "$MAKE_TEMPLATE" != "1" ]]; then
    echo "    MAKE_TEMPLATE=0, leaving CT $CTID as a stopped container"
    return
  fi

  log "Converting CT $CTID to a template"
  pct template "$CTID"
}

# -------------------------------------------------------------------- RUN ---

main() {
  preflight
  download_template
  create_container
  map_user_ids
  start_container
  create_user
  install_docker
  create_shared_group
  make_template

  note_manual "Part 5 clones this image: assets/building-a-home-server-pt5/setup.sh, or by hand with 'pct clone ${CTID} 101 --hostname arrs --full 1'"

  log "Done."
  if [[ "$MAKE_TEMPLATE" == "1" ]]; then
    printf '\nCT %s is now a template. It can be cloned, not started.\n' "$CTID"
  else
    printf '\nCT %s is built and stopped, ready to clone.\n' "$CTID"
  fi

  if ((${#MANUAL_STEPS[@]})); then
    printf '\nStill to do:\n'
    printf '  - %s\n' "${MANUAL_STEPS[@]}"
    printf '\n'
  fi
}

main "$@"

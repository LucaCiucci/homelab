#!/bin/bash
set -euo pipefail

#here="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
script_name="$(basename "$0")"

SSD=/mnt/rpi-data
SNAPSHOTS_DIR="${SSD}/.snapshots"
TIMESTAMP=$(date +%Y%m%dT%H%M%S)
COMPOSE_FILE="$(dirname "$0")/docker-compose.yaml"

if [ -t 1 ]; then
    is_terminal=yes
else
    is_terminal=no
fi

# color a string if we're in a terminal
colored() {
    local color="$1"; shift
    local text="$*"

    if [ "$is_terminal" = "yes" ]; then
        case "$color" in
            "blue") color_code="\033[34m" ;; # blue
            "green") color_code="\033[32m" ;; # green
            "red") color_code="\033[31m" ;; # red
            *) color_code="" ;;
        esac
        reset_code="\033[0m"
        echo -e "${color_code}${text}${reset_code}"
    else
        echo "$text"
    fi
}

log() {
    local level="${1:?}"; shift

    date_str=$(date +%H:%M:%S)
    prefix="[$date_str $(colored "green" "$level") $script_name]"
    echo "$prefix $*" >&2
}

info() {
    log "INFO" "$@"
}

is_service_up() {
    local service="${1:?}"; shift
    docker compose -f "$COMPOSE_FILE" ps -q "$service" | grep -q .
}

stop_service() {
    local service="${1:?}"; shift
    info "Stopping $service"
    docker compose -f "$COMPOSE_FILE" stop "$service"
}

start_service() {
    local service="${1:?}"; shift
    info "Starting $service"
    docker compose -f "$COMPOSE_FILE" start "$service"
}

# Each entry: "container:subvolume"
SERVICES=(
    "gitolite:@repos"
    "samba:@drive"
    "restic:@restic"
    "vaultwarden:@vaultwarden"
)

mkdir -p "$SNAPSHOTS_DIR"

for entry in "${SERVICES[@]}"; do
    container="${entry%%:*}"
    subvol="${entry##*:}"
    src="${SSD}/${subvol}"
    dst="${SNAPSHOTS_DIR}/${subvol}-${TIMESTAMP}"

    is_up=$(is_service_up "$container" && echo "yes" || echo "no")

    if [ "$is_up" = "yes" ]; then
        stop_service "$container"
    fi

    info "[$container] Snapshotting $src -> $dst"
    sudo btrfs subvolume snapshot -r "$src" "$dst"

    if [ "$is_up" = "yes" ]; then
        start_service "$container"
    fi
done

info "Done. Snapshots in $SNAPSHOTS_DIR:"
ls "$SNAPSHOTS_DIR"

#!/usr/bin/env bash
set -euo pipefail

source "$HOME/containers/aliases.sh"

CONTAINERS_ROOT="$HOME/containers"

IMAGE_NAME="base"
BUILD_ALL=1

# --- parse args ---
if [ $# -ge 1 ]; then
  if [[ "$1" != --* ]]; then
    IMAGE_NAME="$1"
    shift
  fi
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --no-build-all)
      BUILD_ALL=0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

build_image() {
  local name="$1"
  local dir="$CONTAINERS_ROOT/$name"
  local cf="$dir/Containerfile"

  if [ ! -f "$cf" ]; then
    echo ">>> Skip build: $name (no Containerfile)"
    return 0
  fi

  echo ">>> Building localhost/$name:latest"
  podman build \
    -f "$cf" \
    -t "localhost/$name:latest" \
    "$dir"
}

image_name() {
  podman inspect "$1" --format '{{.ImageName}}' 2>/dev/null
}

managed_image_name() {
  local img name
  img="$(image_name "$1")"

  if [[ "$img" =~ ^localhost/([^:]+):latest$ ]]; then
    name="${BASH_REMATCH[1]}"
    if [ -f "$CONTAINERS_ROOT/$name/Containerfile" ]; then
      echo "$name"
      return 0
    fi
  fi

  return 1
}

is_toolbox() {
  [ "$(podman inspect "$1" --format '{{index .Config.Labels "com.github.containers.toolbox"}}' 2>/dev/null)" = "true" ]
}

# --- 1. Build target image ---
build_image "$IMAGE_NAME"

# --- 2. base -> optionally build all ---
if [ "$IMAGE_NAME" = "base" ] && [ "$BUILD_ALL" -eq 1 ]; then
  echo ">>> base built -> building all images..."

  for dir in "$CONTAINERS_ROOT"/*; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"

    [ "$name" = "base" ] && continue
    [ -f "$dir/Containerfile" ] || continue

    build_image "$name"
  done
fi

echo ">>> Build done"
echo ">>> Rebuilding containers..."

for container in $(podman ps -a --format '{{.Names}}'); do
  managedName=""
  if ! managedName="$(managed_image_name "$container")"; then
    echo "Skipping $container (not managed)"
    continue
  fi

  if [ "$IMAGE_NAME" = "base" ]; then
    if is_toolbox "$container"; then
      echo "Recreating $container (toolbox, base rebuild)"
      tc "$container" --no-enter
    else
      echo "Recreating $container (distrobox, base rebuild)"
      dc "$container" --no-enter
    fi
    continue
  fi

  if [ "$managedName" = "$IMAGE_NAME" ]; then
    if is_toolbox "$container"; then
      echo "Recreating $container (toolbox, image match)"
      tc "$container" --no-enter
    else
      echo "Recreating $container (distrobox, image match)"
      dc "$container" --no-enter
    fi
  else
    echo "Skipping $container (managed=$managedName, target=$IMAGE_NAME)"
  fi
done

echo ">>> Done"

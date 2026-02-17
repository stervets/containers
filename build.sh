#!/usr/bin/env bash
set -euo pipefail

source "$HOME/containers/aliases.sh"

CONTAINERS_ROOT="$HOME/containers"
IMAGE_NAME="${1:-base}"

CONTAINER_DIR="$CONTAINERS_ROOT/$IMAGE_NAME"
CONTAINERFILE_PATH="$CONTAINER_DIR/Containerfile"

if [ ! -f "$CONTAINERFILE_PATH" ]; then
  echo "Containerfile not found: $CONTAINERFILE_PATH" >&2
  exit 1
fi

echo ">>> Building localhost/$IMAGE_NAME:latest"

podman build \
  -f "$CONTAINERFILE_PATH" \
  -t "localhost/$IMAGE_NAME:latest" \
  "$CONTAINER_DIR"

echo ">>> Build done"
echo ">>> Rebuilding containers..."

image_name() {
  podman inspect "$1" --format '{{.ImageName}}' 2>/dev/null
}

# Возвращает имя managed-образа (например "base", "test"), если:
# - image == localhost/<name>:latest
# - существует $HOME/containers/<name>/Containerfile
# Иначе возвращает пусто.
managed_image_name() {
  local img
  img="$(image_name "$1")"

  # Только localhost/<name>:latest
  if [[ "$img" =~ ^localhost/([^:]+):latest$ ]]; then
    local name="${BASH_REMATCH[1]}"
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

for container in $(podman ps -a --format '{{.Names}}'); do
  # 1) фильтр: трогаем только "managed" контейнеры
  managedName=""
  if managedName="$(managed_image_name "$container")"; then
    : # ok
  else
    echo "Skipping $container (not managed)"
    continue
  fi

  # 2) логика пересоздания
  if [ "$IMAGE_NAME" = "base" ]; then
    # base rebuild -> пересоздаём ВСЕ managed контейнеры
    if is_toolbox "$container"; then
      echo "Recreating $container (toolbox, base rebuild)"
      tc "$container" --no-enter
    else
      echo "Recreating $container (distrobox, base rebuild)"
      dc "$container" --no-enter
    fi
  else
    # rebuild конкретного образа -> только контейнеры, которые реально на нём
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
  fi
done

echo ">>> Done"

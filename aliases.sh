# --- toolbox quick enter
t() {
  if [ -z "$1" ]; then
    toolbox enter atomcore
  else
    toolbox enter "$1"
  fi
}

# --- toolbox create from my base image
tc() {
  if [ -z "${1:-}" ]; then
    echo "usage: tc <container_name> [--no-enter]" >&2
    return 2
  fi

  local containerName="$1"
  local noEnter="${2:-}"

  local imageName="localhost/$containerName:latest"
  if ! podman image exists "$imageName" 2>/dev/null; then
    imageName="localhost/base:latest"
  fi

  toolbox rm "$containerName" --force >/dev/null 2>&1 || true
  toolbox create "$containerName" --image "$imageName"

  if [ "$noEnter" != "--no-enter" ]; then
    t "$containerName"
  fi
}


# --- toolbox remove
tr() {
  if [ -z "$1" ]; then
    echo "usage: tr <container_name>" >&2
    return 2
  fi
  toolbox rm "$1" --force
}

# --- distrobox enter
d() {
  if [ -z "$1" ]; then
    echo "usage: d <container_name>" >&2
    return 2
  fi
  distrobox enter "$1"
}

# --- distrobox create (home = ~/env/<name>) + immutable-эмуляция
dc() {
  if [ -z "${1:-}" ]; then
    echo "usage: dc <container_name> [--no-enter]" >&2
    return 2
  fi

  local containerName="$1"
  local noEnter="${2:-}"

  local envDirectory="$HOME/env/$containerName"

  # если мы стоим внутри env/<name> — выйти, иначе словим getcwd ад
  if [[ "$PWD" == "$envDirectory" || "$PWD" == "$envDirectory"/* ]]; then
    cd "$HOME"
  fi

  local containersRoot="$HOME/containers"
  local baseHome="$containersRoot/base/home"
  local containerHome="$containersRoot/$containerName/home"
  local postinstall="$containersRoot/base/postinstall.sh"
  local containerPostinstall="$containersRoot/$containerName/postinstall.sh"

  # 1) снести контейнер + env
  dr "$containerName"
  mkdir -p "$envDirectory"

  # 2) overlay home: base -> container
  [ -d "$baseHome" ] && cp -a "$baseHome/." "$envDirectory/"
  [ -d "$containerHome" ] && cp -a "$containerHome/." "$envDirectory/"

  # 3) .ssh всегда ссылка на хост
  rm -rf "$envDirectory/.ssh"
  ln -s "$HOME/.ssh" "$envDirectory/.ssh"

  # 4) выбрать образ: localhost/<name>:latest если есть, иначе base
  local imageName="localhost/$containerName:latest"
  if ! podman image exists "$imageName" 2>/dev/null; then
    imageName="localhost/base:latest"
  fi

  # 5) создать контейнер + label "мой"
  distrobox create \
    --name "$containerName" \
    --home "$envDirectory" \
    --image "$imageName"

  # 6) postinstall base (если есть)
  if [ -f "$postinstall" ]; then
    cp -f "$postinstall" "$envDirectory/.postinstall.sh"
    chmod +x "$envDirectory/.postinstall.sh"
    distrobox enter "$containerName" -- bash -lc '$HOME/.postinstall.sh'
    rm -f "$envDirectory/.postinstall.sh"
  fi

  # 7) postinstall контейнера (если есть)
  if [ -f "$containerPostinstall" ]; then
    cp -f "$containerPostinstall" "$envDirectory/.postinstall.sh"
    chmod +x "$envDirectory/.postinstall.sh"
    distrobox enter "$containerName" -- bash -lc '$HOME/.postinstall.sh'
    rm -f "$envDirectory/.postinstall.sh"
  fi

  # 8) заходить только если не попросили --no-enter
  if [ "$noEnter" != "--no-enter" ]; then
    d "$containerName"
  fi
}

# --- distrobox remove + удалить home
dr() {
  if [ -z "$1" ]; then
    echo "usage: dr <container_name>" >&2
    return 2
  fi

  local containerName="$1"
  distrobox rm "$containerName" --force >/dev/null 2>&1 || true
  rm -rf "$HOME/env/$containerName"
}

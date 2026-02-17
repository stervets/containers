set -euo pipefail

export NVM_DIR="$HOME/.config/nvm"
mkdir -p "$NVM_DIR"

if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh \
    | NVM_DIR="$NVM_DIR" bash
fi

source "$NVM_DIR/nvm.sh"

nvm install 24
nvm alias default 24
corepack enable

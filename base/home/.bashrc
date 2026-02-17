# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
  PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi

export PATH
export EDITOR=vim

bind 'set enable-bracketed-paste off'

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

alias la="ls -la"
alias vib="vim $HOME/.bashrc"
alias vis="source $HOME/.bashrc"
alias z='flatpak-spawn --host flatpak run dev.zed.Zed'

containerName="$(sed -n 's/^name="\([^"]*\)".*/\1/p' /run/.containerenv)"
if [ -n "$containerName" ]; then
    PS1="\[\e[0;37m\]\]📦[\[\e[38;5;41m\]$containerName\[\e[0m\]:\[\e[1;34m\]\w\[\e[0;37m\]\]]$ \[\e[0m\]"
    printf "\n📦 Container\033[1;34m %s\033[0m \n\n" "$containerName"
fi

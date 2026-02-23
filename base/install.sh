#!/usr/bin/env bash
set -euo pipefail

sed -i 's|^metalink=|#metalink=|g' /etc/yum.repos.d/fedora*.repo && \
sed -i 's|^#baseurl=.*|baseurl=https://ftp.uni-stuttgart.de/fedora/releases/$releasever/Everything/$basearch/os/|g' /etc/yum.repos.d/fedora.repo && \
sed -i 's|^#baseurl=.*|baseurl=https://ftp.uni-stuttgart.de/fedora/updates/$releasever/Everything/$basearch/|g' /etc/yum.repos.d/fedora-updates.repo && \
(sed -i 's|^enabled=1|enabled=0|g' /etc/yum.repos.d/fedora-cisco-openh264.repo || true)

dnf -y update

### COMMON TOOLS ###
dnf -y install \
    curl \
    wget \
    vim \
    mc \
    git \
    ssh \
    openssl \
    ca-certificates \
    ncurses-term \
    kitty-terminfo \
    python3 \
    pkgconf-pkg-config \
    ripgrep \
    fd-find \
    && dnf -y clean all

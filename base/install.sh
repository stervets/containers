#!/usr/bin/env bash
set -euo pipefail

dnf -y update

### COMMON TOOLS ###
dnf -y install \
    vim \
    mc \
    && dnf -y clean all

#!/bin/bash

export HOME=/home/ubuntu
wget -qO- https://astral.sh/uv/install.sh | sh

# shellcheck disable=SC1091
source "$HOME"/.local/bin/env

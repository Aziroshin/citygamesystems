#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2023 Aziroshin (Christian Knuchel)
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

export BLEND_FILE_PATH="$1"
"$SCRIPT_DIR/start.sh"
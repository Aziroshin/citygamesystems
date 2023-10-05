#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2023 Aziroshin (Christian Knuchel)
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

if [ -e "$SCRIPT_DIR/.env" ]; then
  . "$SCRIPT_DIR/.env"
fi


### BEGIN: Config #############################################################
### Default config (env-override/configure as you require).
BLENDER_BIN="${BLENDER_BIN:-"blender"}"
ADDON_NAME="${ADDON_NAME:-"raw_export"}"
BLEND_FILE_NAME="${BLEND_FILE_NAME:-"${ADDON_NAME}.blend"}"
BLENDER_CONFIG_DIR="${BLENDER_CONFIG_DIR\
:-"$SCRIPT_DIR/blender_user_config"}"
OVERRIDE_BLENDER_USER_RESOURCES="${OVERRIDE_BLENDER_USER_RESOURCES:-"no"}"
OVERRIDE_BLENDER_USER_CONFIG="${OVERRIDE_BLENDER_USER_CONFIG:-"no"}"
OVERRIDE_BLENDER_USER_SCRIPTS="${OVERRIDE_BLENDER_USER_SCRIPTS:-"yes"}"


### Other config (not expected to be env-overriden/configured manually,
### but can be).
ADDON_DIR="${ADDON_DIR:-"$(realpath "$SCRIPT_DIR/../$ADDON_NAME")"}"
# `m1` limits to the first line and `-o` only prints the match.
BLENDER_VERSION="${BLENDER_VERSION\
:-"$("$BLENDER_BIN" --version | grep -m1 -o "[0-9]\.[0-9]")"}"
BLENDER_VERSION_BASE_DIR="${BLENDER_VERSION_BASE_DIR\
:-$BLENDER_CONFIG_DIR/$BLENDER_VERSION}"
BLENDER_VERSION_SCRIPTS_DIR="${BLENDER_VERSION_SCRIPTS_DIR\
:-"$BLENDER_VERSION_BASE_DIR/scripts"}"
BLENDER_VERSION_CONFIG_DIR="${BLENDER_VERSION_CONFIG_DIR\
:-"$BLENDER_VERSION_BASE_DIR/config"}"
BLENDER_VERSION_ADDONS_DIR="${BLENDER_VERSION_ADDONS_DIR\
:-"$BLENDER_VERSION_BASE_DIR/scripts/addons"}"
BLENDER_VERSION_PRESETS_DIR="${BLENDER_VERSION_PRESETS_DIR\
:-"$BLENDER_VERSION_SCRIPTS_DIR/presets"}"
BLENDER_SYSTEM_PRESETS_DIR="${BLENDER_SYSTEM_PRESETS_DIR\
:-"$HOME/.config/blender/$BLENDER_VERSION/scripts/presets"}"
BLENDER_VERSION_ADDON_DIR_LINK="${BLENDER_VERSION_ADDON_DIR_LINK\
:-"$BLENDER_VERSION_ADDONS_DIR/$ADDON_NAME"}"
BLENDER_VERSION_ADDON_DIR_LINK_TARGET="${BLENDER_VERSION_ADDON_DIR_LINK_TARGET\
:-"../../../../../$ADDON_NAME"}"
BLEND_FILE_PATH="${BLEND_FILE_PATH:-"${SCRIPT_DIR}/$BLEND_FILE_NAME"}"
### END: Config ###############################################################


### BEGIN: Sanity Checks ######################################################
if [ ! -e "$ADDON_DIR" ]; then
  printf "The addon dir, configured to be at "
  printf "\"%s\", doesn't exist. Exiting.\n" "${ADDON_DIR}"
fi
### END: Sanity Checks ########################################################


### BEGIN: Action! ############################################################
if [ ! -e "$BLENDER_VERSION_ADDONS_DIR" ]; then
  mkdir -p "$BLENDER_VERSION_ADDONS_DIR"
fi

# In case either are later changed to "yes, make sure the overriding config
# directory exists, else the user's config might get overwritten with defaults.
if [ "$OVERRIDE_BLENDER_USER_CONFIG" = "yes" ] || [ ! "$OVERRIDE_BLENDER_USER_RESOURCES" = "yes" ]; then
  mkdir -p "$BLENDER_VERSION_CONFIG_DIR"
fi

if [ ! "$OVERRIDE_BLENDER_USER_CONFIG" = "yes" ] || [ ! "$OVERRIDE_BLENDER_USER_RESOURCES" = "yes" ]; then
    if [ ! -e "$BLENDER_VERSION_PRESETS_DIR" ]; then
      ln -s "$BLENDER_SYSTEM_PRESETS_DIR" "$BLENDER_VERSION_PRESETS_DIR"
    fi

    if [ ! -e "$BLENDER_VERSION_PRESETS_DIR/__init__.py" ]; then
      printf "ERROR: The presets-dir at "
      printf  "\"%s\" is empty. " "$BLENDER_VERSION_PRESETS_DIR"
      printf "This is a sign something went wrong when symlinking the presets-dir "
      printf "from the user's home directory. Since this could result in the "
      printf "user's blender settings getting overwritten with defaults, the "
      printf "script won't proceed any further. "
      printf "Exiting.\n"
      exit 1;
    fi
fi

# TODO [bug,prio=low]: Evaluates to true even if it exists.
if [ ! -e "$BLENDER_VERSION_ADDON_DIR_LINK" ]; then
    ln -s "$BLENDER_VERSION_ADDON_DIR_LINK_TARGET" \
    "$BLENDER_VERSION_ADDON_DIR_LINK"
fi


### Export Blender env vars and run it.
if [ "$OVERRIDE_BLENDER_USER_RESOURCES" = "yes" ]; then
  export BLENDER_USER_RESOURCES="$BLENDER_VERSION_BASE_DIR"
fi
if [ "$OVERRIDE_BLENDER_USER_CONFIG" = "yes" ]; then
  export BLENDER_USER_CONFIG="$BLENDER_VERSION_CONFIG_DIR"
fi
if [ "$OVERRIDE_BLENDER_USER_SCRIPTS" = "yes" ]; then
  export BLENDER_USER_SCRIPTS="$BLENDER_VERSION_SCRIPTS_DIR"
fi
"$BLENDER_BIN" "$BLEND_FILE_PATH"
### END: Action! ##############################################################

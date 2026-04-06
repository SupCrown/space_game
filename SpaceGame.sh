#!/bin/sh
printf '\033c\033]0;%s\a' SpaceGame
base_path="$(dirname "$(realpath "$0")")"
"$base_path/SpaceGame.x86_64" "$@"

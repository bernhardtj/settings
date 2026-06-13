#!/usr/bin/env bash
set -euo pipefail

settings_repo_root() {
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

settings_dry_run() {
    [[ ${SETTINGS_DRY_RUN:-} == 1 || ${SETTINGS_DRY_RUN:-} == true ]]
}

settings_run() {
    if settings_dry_run; then
        printf '+'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

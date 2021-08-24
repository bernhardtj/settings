.local/bin/software-update
#!/bin/bash
BIN="$(basename "$0")"

if [[ $BIN == software-update ]]; then
    BIN=$1
    unset CONTINUE_ARGS
else
    CONTINUE_ARGS=("$BIN" "$@")
fi

if [[ ! $BIN ]]; then
    echo "usage: $(basename "$0") <binary_to_update>"
    exit 1
fi

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../80.software.sh"
_software_iterate_recipes_begin
if [[ $link == "$BIN" ]]; then
    for b in $(recipe_bin); do rm -f "$HOME/.local/bin/$b"; done
    _software_entrypoint "${CONTINUE_ARGS[@]}"
    exit $?
fi
_software_iterate_recipes_end

echo "settings/software: couldn't find a recipe for $BIN."
exit 1

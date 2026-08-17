set shell := ["bash", "-c"]

# List available setup names.
list:
    bin/settings-setup list

# Show the inheritance chain for a setup.
lineage setup="default":
    bin/settings-setup lineage {{setup}}

# Print the resolved apply plan as JSON without changing the machine.
plan setup="default":
    bin/settings-apply --plan {{setup}}

# Apply dotfiles and lifecycle scripts for a setup.
apply setup="default":
    bin/settings-apply {{setup}}

# Save installed dotfile edits and enabled GNOME extensions into a setup.
save setup="default":
    bin/settings-save {{setup}}

# Preview installed dotfile and GNOME extension changes without writing.
save-dry setup="default":
    bin/settings-save {{setup}} --dry-run

# Run install groups, actions, and hooks for a setup.
install setup="default" group="all":
    bin/settings install {{setup}} {{group}}

# Show install commands without mutating the host.
install-dry setup="default" group="all" provider="auto":
    bin/settings-install {{setup}} {{group}} --dry-run --provider {{provider}}

# Install or update one on-demand software target.
software target:
    bin/settings-software install {{target}}

# List on-demand software targets provided by recipes.
software-list:
    bin/settings-software list

# Create ~/.local/bin shims for on-demand software installs.
software-setup:
    bin/settings-software setup-shims

# Run unit and integration tests.
test:
    python3 -m unittest discover -s tests

# Validate one setup's metadata, inheritance, settings, actions, and recipes.
validate setup="default":
    bin/settings-setup validate {{setup}}

# Validate every setup.
validate-all:
    for setup in $(bin/settings-setup list); do bin/settings-setup validate "$setup"; done

# Run the local CI checks.
ci:
    just validate-all
    just test

# Run CI in a clean Fedora container with Podman.
ci-podman:
    podman run --rm -it -v "$PWD:/workspace:Z" -w /workspace fedora:latest bash -lc 'dnf install -y python3 bash just ShellCheck && just ci'

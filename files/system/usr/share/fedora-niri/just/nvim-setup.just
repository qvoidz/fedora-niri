nvim-setup yes="":
    #!/usr/bin/env bash
    if [ "{{yes}}" = "-y" ] || [ "{{yes}}" = "--yes" ]; then
        exec /usr/libexec/fedora-niri-config-setup nvim --yes
    else
        exec /usr/libexec/fedora-niri-config-setup nvim
    fi

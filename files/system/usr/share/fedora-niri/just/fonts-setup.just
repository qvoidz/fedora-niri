fonts-setup yes="":
    #!/usr/bin/env bash
    if [ "{{yes}}" = "-y" ] || [ "{{yes}}" = "--yes" ]; then
        exec /usr/libexec/fedora-niri-config-setup fonts --yes
    else
        exec /usr/libexec/fedora-niri-config-setup fonts
    fi

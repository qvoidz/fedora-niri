dms-setup yes="":
    #!/usr/bin/env bash
    if [ "{{yes}}" = "-y" ] || [ "{{yes}}" = "--yes" ]; then
        exec /usr/libexec/fedora-niri-config-setup dms --yes
    else
        exec /usr/libexec/fedora-niri-config-setup dms
    fi

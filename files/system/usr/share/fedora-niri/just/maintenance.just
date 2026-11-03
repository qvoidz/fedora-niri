cleanup yes="":
    #!/usr/bin/env bash
    if [ "{{yes}}" = "-y" ] || [ "{{yes}}" = "--yes" ]; then
        exec /usr/libexec/fedora-niri-cleanup --yes
    else
        exec /usr/libexec/fedora-niri-cleanup
    fi

user-dirs yes="":
    #!/usr/bin/env bash
    if [ "{{yes}}" = "-y" ] || [ "{{yes}}" = "--yes" ]; then
        exec /usr/libexec/fedora-niri-user-dirs --yes
    else
        exec /usr/libexec/fedora-niri-user-dirs
    fi

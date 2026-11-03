# Destructive user-home reset. Requires typing RESET to continue.
cleanup:
    #!/usr/bin/env bash
    exec /usr/libexec/fedora-niri-cleanup

# Pin XDG standard directories to English names, independent of UI language.
user-dirs:
    #!/usr/bin/env bash
    exec /usr/libexec/fedora-niri-user-dirs

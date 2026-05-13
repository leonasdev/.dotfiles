function dbash
    set -l state (mktemp -u)
    set -l c_dim (set_color brblack)
    set -l c_red (set_color -o red)
    set -l c_reset (set_color normal)
    set -l hdr_user "[user]  "$c_dim"Ctrl-R: toggle root"$c_reset
    set -l hdr_root $c_red"[ROOT]"$c_reset"  "$c_dim"Ctrl-R: toggle root"$c_reset
    set -l toggle "if [ -e $state ]; then rm $state; echo '$hdr_user'; else touch $state; echo '$hdr_root'; fi"

    set -l container (docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.Status}}\t{{.Names}}" | \
        fzf --height=40% \
            --layout=reverse \
            --border \
            --header-lines=1 \
            --header="$hdr_user" \
            --bind "ctrl-r:transform-header($toggle)" \
            --prompt=(set_color 24A0ED)"  Connect ❯ "(set_color normal))

    set -l user_args
    test -e $state; and set user_args -u root:root; and rm $state

    if test -n "$container"
        set -l id (echo $container | awk '{print $1}')

        echo (set_color cyan)"Connecting to $id..."(set_color normal)

        docker exec -it $user_args $id /bin/sh -c "[ -e /bin/bash ] && exec /bin/bash || exec /bin/sh"
    end
end

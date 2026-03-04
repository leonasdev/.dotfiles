function dbash
    set -l container (docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.Status}}\t{{.Names}}" | \
        fzf --height=40% \
            --layout=reverse \
            --border \
            --header-lines=1 \
            --prompt=(set_color 24A0ED)"  Connect ❯ "(set_color normal))

    if test -n "$container"
        set -l id (echo $container | awk '{print $1}')
        
        echo (set_color cyan)"Connecting to $id..."(set_color normal)
        
        docker exec -it $id /bin/sh -c "[ -e /bin/bash ] && exec /bin/bash || exec /bin/sh"
    end
end

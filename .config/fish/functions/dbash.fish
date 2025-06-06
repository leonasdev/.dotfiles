function dbash
    set container (docker ps | rg -v "CONTAINER ID" | fzf)
    if not test -z "$container"
        set id (string split ' ' $container)[1]
        docker exec -it $id bash
    end
end

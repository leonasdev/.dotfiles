function ports
    if type -q lsof
        sudo lsof -iTCP -sTCP:LISTEN -P -n
    else
        echo (set_color red)"✘ lsof is not installed."(set_color normal)
    end
end

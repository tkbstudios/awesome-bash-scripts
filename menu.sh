#!/bin/bash

current_path=""

list_files() {
    curl -s "https://api.github.com/repos/tkbstudios/awesome-bash-scripts/contents/$current_path" | grep '"name"' | cut -d '"' -f 4
}

run_script() {
    local script_name=$1
    echo "Running script: $script_name"
    curl -s "https://raw.githubusercontent.com/tkbstudios/awesome-bash-scripts/master/$current_path/$script_name" | bash
}

is_directory() {
    local item_name=$1
    local response=$(curl -s "https://api.github.com/repos/tkbstudios/awesome-bash-scripts/contents/$current_path/$item_name")
    echo "$response" | grep '"type": "dir"' > /dev/null
}

main_menu() {
    while true; do
        echo "Current path: /$current_path"
        PS3="Please enter your choice: "
        options=($(list_files) ".." "Quit")
        select opt in "${options[@]}"; do
            if [[ "$opt" == "Quit" ]]; then
                echo "Goodbye!"
                exit 0
            elif [[ "$opt" == ".." ]]; then
                current_path=$(dirname "$current_path")
                [[ "$current_path" == "." ]] && current_path=""
                break
            elif [[ -n "$opt" ]]; then
                if is_directory "$opt"; then
                    current_path="$current_path/$opt"
                    break
                else
                    run_script "$opt"
                fi
            else
                echo "Invalid option. Try another one."
            fi
        done
    done
}

main_menu

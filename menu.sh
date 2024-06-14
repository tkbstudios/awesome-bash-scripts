#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

current_path=""

list_files() {
    curl -s "https://api.github.com/repos/tkbstudios/awesome-bash-scripts/contents/$current_path" | grep '"name"' | cut -d '"' -f 4
}

run_script() {
    local script_name=$1
    echo -e "${YELLOW}Running script: $script_name${NC}"
    curl -s "https://raw.githubusercontent.com/tkbstudios/awesome-bash-scripts/master/$current_path/$script_name" | bash
}

is_directory() {
    local item_name=$1
    local response=$(curl -s "https://api.github.com/repos/tkbstudios/awesome-bash-scripts/contents/$current_path/$item_name")
    echo "$response" | grep '"type": "dir"' > /dev/null
}

main_menu() {
    while true; do
        echo -e "${BLUE}Current path: /$current_path${NC}"
        PS3="Please enter your choice: "
        options=($(list_files) ".." "Quit")
        select opt in "${options[@]}"; do
            if [[ "$opt" == "Quit" ]]; then
                echo -e "${RED}Goodbye!${NC}"
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
                echo -e "${RED}Invalid option. Try another one.${NC}"
            fi
        done
    done
}

main_menu

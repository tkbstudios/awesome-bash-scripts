#!/bin/bash

# confirm 
confirm() {
    read -p "$1 (y/n): " choice
    case "$choice" in
        y|Y ) return 0;;
        n|N ) return 1;;
        * ) echo "Invalid input. Please enter 'y' or 'n'."; confirm "$1";;
    esac
}

echo "WARNING: This will completely uninstall Docker and remove all Docker data."

# First confirmation
if confirm "Are you sure you want to proceed?"; then
    # Second confirmation
    if confirm "Are you really sure you want to uninstall Docker and remove all Docker data?"; then
        echo "Uninstalling Docker..."

        # Uninstall Docker
        sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
        
        # Remove Docker data
        sudo rm -rf /var/lib/docker
        sudo rm -rf /var/lib/containerd

        echo "Docker has been uninstalled and all Docker data has been removed."
    else
        echo "Uninstallation cancelled."
    fi
else
    echo "Uninstallation cancelled."
fi

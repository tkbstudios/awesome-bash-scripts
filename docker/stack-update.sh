#!/bin/bash

command_exists() {
    command -v "$1" &> /dev/null
}

# Install docker option because why not
install_docker() {
    echo "Docker is not installed. Installing Docker..."
    curl -fsSL https://raw.githubusercontent.com/tkbstudios/awesome-bash-scripts/main/docker/install.sh -o install_docker.sh
    chmod +x install_docker.sh
    sudo ./install_docker.sh
}

# some goofy ahh systems use "docker-compose" and some "docker compose"
if command_exists docker-compose; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif command_exists docker && docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "Neither docker-compose nor docker compose is installed."
    read -p "Do you want to install Docker? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        install_docker
        if command_exists docker && docker compose version &> /dev/null; then
            DOCKER_COMPOSE_CMD="docker compose"
        elif command_exists docker-compose; then
            DOCKER_COMPOSE_CMD="docker-compose"
        else
            echo "Docker installation failed or docker compose command not found."
            exit 1
        fi
    else
        echo "Docker installation skipped. Exiting..."
        exit 1
    fi
fi

# Pull the images
echo "Pulling the latest images..."
sudo $DOCKER_COMPOSE_CMD pull

# Shut the current stack down
echo "Bringing down the current containers..."
sudo $DOCKER_COMPOSE_CMD down

# Bring it back up detached (background)
echo "Bringing up the containers in detached mode..."
sudo $DOCKER_COMPOSE_CMD up -d

echo "Docker Compose update completed."

#!/bin/bash

log_info() {
    echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S') - $1" >&2
}

log_debug() {
    if [ "$DEBUG_MODE" = true ]; then
        echo "[DEBUG] $(date +'%Y-%m-%d %H:%M:%S') - $1" >&2
    fi
}

if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run as root. Use sudo $0 <new_node_id> <api_key>"
    exit 1
fi

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <panel_url> <new_node_id> <api_key>"
    echo "API Key should only have READ nodes/locations permission!"
    echo "You can generate a token from the configuration section in the new node."
    exit 1
fi

PANEL_URL=$1
NEW_NODE_ID=$2
API_KEY=$3

WINGS_DIR="/etc/pterodactyl"
NODES_ENDPOINT="$PANEL_URL/api/application/nodes/$NEW_NODE_ID"
LOCATIONS_ENDPOINT="$PANEL_URL/api/application/locations"

install_packages() {
    log_info "Installing required packages..."
    sudo apt update
    sudo apt install -y curl jq apt-transport-https ca-certificates gnupg lsb-release
    curl -sSL https://raw.githubusercontent.com/tkbstudios/awesome-bash-scripts/main/docker/install.sh | bash
}

install_certbot() {
    log_info "Installing Certbot..."
    sudo apt install -y python3 python3-venv libaugeas0
    sudo apt-get remove -y certbot
    sudo python3 -m venv /opt/certbot/
    sudo /opt/certbot/bin/pip install --upgrade pip
    sudo /opt/certbot/bin/pip install certbot certbot-nginx
    sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
}

fetch_node_info() {
    log_info "Fetching node information..."
    response=$(curl -s -X GET "$NODES_ENDPOINT" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Accept: application/json")

    if echo "$response" | grep -q '"attributes"'; then
        FQDN=$(echo "$response" | jq -r '.attributes.fqdn')
        NAME=$(echo "$response" | jq -r '.attributes.name')
        LOCATION_ID=$(echo "$response" | jq -r '.attributes.location_id')
        PORT=$(echo "$response" | jq -r '.attributes.daemon_listen')
        echo "Node ID: $NEW_NODE_ID"
        echo "Name: $NAME"
        echo "FQDN: $FQDN"
        echo "Port: $PORT"
        echo "Location ID: $LOCATION_ID"
        fetch_location_info $LOCATION_ID
    else
        log_error "Failed to fetch node information. Please check the node ID and API key."
        exit 1
    fi
}

fetch_location_info() {
    local location_id=$1
    log_info "Fetching location information for location ID: $location_id..."
    response=$(curl -s -X GET "$LOCATIONS_ENDPOINT/$location_id" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Accept: application/json")

    if echo "$response" | grep -q '"attributes"'; then
        LOCATION_SHORT=$(echo "$response" | jq -r '.attributes.short')
        LOCATION_LONG=$(echo "$response" | jq -r '.attributes.long')
        echo "Location Short: $LOCATION_SHORT"
        echo "Location Long: $LOCATION_LONG"
    else
        log_error "Failed to fetch location information. Please check the API key."
    fi
}

# TODO: make this actually work
check_node_status() {
    log_info "Checking node status..."
    NODE_API_URL="https://$FQDN:$PORT/api/system"

    if curl --silent --max-time 5 --output /dev/null --head --fail "$NODE_API_URL"; then
        log_error "Node responded. Canceling installation."
        exit 0
    else
        log_info "Node did not respond. Proceeding with installation."
    fi
}

setup_ssl() {
    log_info "Setting up SSL certificates..."
    sudo certbot -d "$FQDN" --manual --preferred-challenges dns certonly
}

configure_node() {
    log_info "Configuring the new node..."
    cd $WINGS_DIR
    sudo wings configure --panel-url $PANEL_URL --token $API_KEY --node $NEW_NODE_ID
}

install_packages
install_certbot
fetch_node_info
#check_node_status # TODO: make it work, disabled because it'll always fail.
setup_ssl
configure_node

log_info "Node has been set up as $FQDN at $LOCATION_SHORT."

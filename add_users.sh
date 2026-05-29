#!/bin/bash

# --- Configuration ---
VIKUNJA_CONTAINER="vikunja-vikunja-1"
VIKUNJA_BINARY="/app/vikunja/vikunja"
DEFAULT_PASSWORD="changeme"

# UI Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${BOLD}======================================${NC}"
echo -e "${BOLD}    Vikunja Team Onboarding TUI       ${NC}"
echo -e "${BOLD}======================================${NC}"

# Check if the Vikunja container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${VIKUNJA_CONTAINER}$"; then
    echo -e "${RED}Error: Container '${VIKUNJA_CONTAINER}' is not running.${NC}"
    exit 1
fi

while true; do
    echo -e "\n${BOLD}--- Create New Account ---${NC}"

    read -p "Username        : " USERNAME
    read -p "Email           : " EMAIL

    # Final field check
    if [[ -z "$USERNAME" || -z "$EMAIL" ]]; then
        echo -e "${RED}Username and Email are required. Restarting entry...${NC}"
        continue
    fi

    echo -e "\nProvisioning user ${BOLD}${USERNAME}${NC}..."

    # Execution command
    docker exec -it "$VIKUNJA_CONTAINER" "$VIKUNJA_BINARY" user create \
        --username "$USERNAME" \
        --email "$EMAIL" \
        --password "$DEFAULT_PASSWORD"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SUCCESS:${NC} Account for $USERNAME is ready."
    else
        echo -e "${RED}FAILURE:${NC} Could not create user. Check if username/email is taken."
    fi

    echo -e "--------------------------------------"
    read -p "Add another user? (y/n): " AGAIN
    [[ "$AGAIN" != "y" ]] && break
done

echo -e "\n${BOLD}Done!${NC} Remember to add these users to your shared team via the Web UI."

# Print out the current user list
echo -e "\n${BOLD}--- Current Vikunja Users ---${NC}"
docker exec -it "$VIKUNJA_CONTAINER" "$VIKUNJA_BINARY" user list

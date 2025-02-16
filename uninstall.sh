#!/bin/bash

# Colors for output
RESET_COLOR="\033[0m"
GREEN="\033[1;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"

echo "Removing gq-cloud from all locations..."

# Array of locations to check and clean
locations=(
    "/usr/local/bin/gq-cloud"
    "$HOME/bin/gq-cloud"
    "/usr/bin/gq-cloud"
)

# Remove files from all locations
for location in "${locations[@]}"; do
    if [ -f "$location" ] || [ -L "$location" ]; then
        echo "Found gq-cloud in: $location"
        if [[ "$location" == /usr/* ]]; then
            sudo rm -f "$location" && echo -e "${GREEN}✓ Removed from $location${RESET_COLOR}" || echo -e "${RED}✗ Failed to remove from $location${RESET_COLOR}"
        else
            rm -f "$location" && echo -e "${GREEN}✓ Removed from $location${RESET_COLOR}" || echo -e "${RED}✗ Failed to remove from $location${RESET_COLOR}"
        fi
    fi
done

# Verify complete removal
if ! command -v gq-cloud &> /dev/null; then
    echo -e "${GREEN}✓ gq-cloud has been successfully uninstalled${RESET_COLOR}"
else
    remaining_location=$(which gq-cloud)
    echo -e "${YELLOW}! gq-cloud is still present in: $remaining_location${RESET_COLOR}"
    echo "You may need to remove it manually or contact your system administrator"
fi

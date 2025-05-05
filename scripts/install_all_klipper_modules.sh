#!/bin/bash

# This script runs all the individual Klipper module installation scripts.

# Exit immediately if a command exits with a non-zero status
set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "--- Starting All Klipper Module Installations ---"

# Define the list of installation scripts to run
# Add or remove scripts from this list as needed
INSTALL_SCRIPTS=(
    "install_belay_klipper_module.sh"
    "install_beacon_klipper_module.sh"
    "install_led_effect_klipper_module.sh"
    "install_tradrack_klipper_module.sh"
    "install_klipperscreen_klipper_module.sh"    
    # Add other install scripts here
)

# Loop through the scripts and execute them
for script_name in "${INSTALL_SCRIPTS[@]}"; do
    script_path="${SCRIPT_DIR}/${script_name}"
    if [ -f "$script_path" ]; then
        echo "" # Add a blank line for separation
        echo "--- Running $script_name ---"
        # Execute the script
        bash "$script_path"
        # Check the exit status (optional, as set -e should handle it)
        if [ $? -ne 0 ]; then
            echo "Error: $script_name failed. Aborting."
            exit 1
        fi
        echo "--- Finished $script_name ---"
    else
        echo "Warning: Script not found at $script_path. Skipping."
    fi
done

echo ""
echo "--- All Klipper Module Installations Completed ---"

exit 0
#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "--- Starting Beacon Installation and Configuration ---"

# Define the likely path to moonraker.conf
# Adjust this path if your configuration directory is different (e.g., ~/printer_data/config)
moonraker_conf_path="${HOME}/printer_data/config/moonraker.conf"

# Check if the moonraker config file exists
if [ ! -f "$moonraker_conf_path" ]; then
        echo "Error: Moonraker configuration file not found at $moonraker_conf_path"
        echo "Please ensure Klipper and Moonraker are installed correctly or adjust the path in the script."
        exit 1
fi

# --- Beacon Installation ---
echo "Installing Beacon module..."
cd ~
if [ -d "beacon_klipper" ]; then
    echo "beacon_klipper directory already exists. Skipping clone."
else
    git clone https://github.com/beacon3d/beacon_klipper.git
fi
# Check if install script exists before running
if [ -f "./beacon_klipper/install.sh" ]; then
    ./beacon_klipper/install.sh
else
    echo "Beacon install script not found at ./beacon_klipper/install.sh"
    echo "Attempting Beacon setup via Moonraker update manager configuration (if applicable)."
fi
echo "Beacon module installation complete."

# --- Add Beacon to Moonraker Update Manager ---
echo "Adding Beacon to Moonraker update manager..."
beacon_config="
[update_manager beacon]
type: git_repo
channel: dev
path: ~/beacon_klipper
origin: https://github.com/beacon3d/beacon_klipper.git
env: ~/klippy-env/bin/python
requirements: requirements.txt
install_script: install.sh
is_system_service: False
managed_services: klipper
info_tags:
  desc=Beacon Surface Scanner
  author=Beacon3D
"

# Check if the beacon update_manager section already exists
if grep -q "\[update_manager beacon\]" "$moonraker_conf_path"; then
    echo "Beacon update_manager section already exists in $moonraker_conf_path. Skipping."
else
    # Append the configuration block to moonraker.conf
    echo "" >> "$moonraker_conf_path" # Add a newline for separation
    echo "$beacon_config" >> "$moonraker_conf_path"
    echo "Beacon update_manager section added to $moonraker_conf_path."
fi

echo "--- Beacon Installation and Configuration Finished ---"
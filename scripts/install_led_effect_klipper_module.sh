#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "--- Starting LED Effect Installation and Configuration ---"

# Define the likely path to moonraker.conf
# Adjust this path if your configuration directory is different (e.g., ~/printer_data/config)
moonraker_conf_path="${HOME}/klipper_config/moonraker.conf"

# Check if the moonraker config file exists
if [ ! -f "$moonraker_conf_path" ]; then
        echo "Error: Moonraker configuration file not found at $moonraker_conf_path"
        echo "Please ensure Klipper and Moonraker are installed correctly or adjust the path in the script."
        exit 1
fi

# --- LED Effect Installation ---
echo "Installing LED Effect module..."
cd ~
if [ -d "klipper-led_effect" ]; then
    echo "klipper-led_effect directory already exists. Skipping clone."
    cd klipper-led_effect
else
    git clone https://github.com/julianschill/klipper-led_effect.git
    cd klipper-led_effect
fi
./install-led_effect.sh
echo "LED Effect module installation complete."

# --- Add LED Effect to Moonraker Update Manager ---
echo "Adding LED Effect to Moonraker update manager..."
led_effect_config="
[update_manager led_effect]
type: git_repo
path: ~/klipper-led_effect
origin: https://github.com/julianschill/klipper-led_effect.git
is_system_service: False
info_tags:
  desc=LED Effect
  author=Julian Schill
"

# Check if the led_effect update_manager section already exists
if grep -q "\[update_manager led_effect\]" "$moonraker_conf_path"; then
    echo "LED Effect update_manager section already exists in $moonraker_conf_path. Skipping."
else
    # Append the configuration block to moonraker.conf
    echo "" >> "$moonraker_conf_path" # Add a newline for separation
    echo "$led_effect_config" >> "$moonraker_conf_path"
    echo "LED Effect update_manager section added to $moonraker_conf_path."
fi

echo "--- LED Effect Installation and Configuration Finished ---"
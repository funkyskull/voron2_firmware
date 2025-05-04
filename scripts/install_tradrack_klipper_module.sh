#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "--- Starting TradRack Installation and Configuration ---"

# Define the likely path to moonraker.conf
# Adjust this path if your configuration directory is different (e.g., ~/printer_data/config)
moonraker_conf_path="${HOME}/klipper_config/moonraker.conf"

# Check if the moonraker config file exists
if [ ! -f "$moonraker_conf_path" ]; then
        echo "Error: Moonraker configuration file not found at $moonraker_conf_path"
        echo "Please ensure Klipper and Moonraker are installed correctly or adjust the path in the script."
        exit 1
fi

# --- TradRack Installation ---
echo "Installing TradRack module..."
cd ~
# Define the URL for the install script
install_script_url="https://raw.githubusercontent.com/Annex-Engineering/TradRack/main/Kalico/klippy_module/install.sh"
# Check if the URL is accessible before attempting download
echo "Checking accessibility of $install_script_url..."
if curl --output /dev/null --silent --head --fail -L "$install_script_url"; then
  echo "URL is accessible. Downloading install script..."
  # Download the script using -LJO to follow redirects and save with original filename
  if ! curl -LJO "$install_script_url"; then
      echo "Error: Failed to download TradRack install script from $install_script_url."
      exit 1
  fi
else
  echo "Error: Could not access TradRack install script at $install_script_url."
  echo "Please check the URL or your network connection."
  exit 1
fi
chmod +x install.sh
./install.sh
rm install.sh
echo "TradRack module installation complete."

# --- Add TradRack to Moonraker Update Manager ---
echo "Adding TradRack to Moonraker update manager..."
trad_rack_config="
[update_manager trad_rack]
type: git_repo
path: ~/trad_rack_klippy_module
origin: https://github.com/Annex-Engineering/TradRack.git
primary_branch: main
managed_services: klipper
info_tags:
  desc=TradRack
  author=Annex Engineering
"

# Check if the trad_rack update_manager section already exists
if grep -q "\[update_manager trad_rack\]" "$moonraker_conf_path"; then
    echo "TradRack update_manager section already exists in $moonraker_conf_path. Skipping."
else
    # Append the configuration block to moonraker.conf
    echo "" >> "$moonraker_conf_path" # Add a newline for separation
    echo "$trad_rack_config" >> "$moonraker_conf_path"
    echo "TradRack update_manager section added to $moonraker_conf_path."
fi

echo "--- TradRack Installation and Configuration Finished ---"
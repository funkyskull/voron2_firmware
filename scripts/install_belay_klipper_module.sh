#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "--- Starting Belay Installation and Configuration ---"

# Define the likely path to moonraker.conf
# Adjust this path if your configuration directory is different (e.g., ~/printer_data/config)
moonraker_conf_path="${HOME}/printer_data/config/moonraker.conf"

# Check if the moonraker config file exists
if [ ! -f "$moonraker_conf_path" ]; then
        echo "Error: Moonraker configuration file not found at $moonraker_conf_path"
        echo "Please ensure Klipper and Moonraker are installed correctly or adjust the path in the script."
        exit 1
fi

# --- Belay Installation ---
echo "Installing Belay module..."
cd ~
# Define the URL for the install script
install_script_url="https://raw.githubusercontent.com/Annex-Engineering/Belay/main/Kalico/klippy_module/install.sh"
# Check if the URL is accessible before attempting download
echo "Checking accessibility of $install_script_url..."
if curl --output /dev/null --silent --head --fail -L "$install_script_url"; then
  echo "URL is accessible. Downloading install script..."
  # Download the script using -LJO to follow redirects and save with original filename
  if ! curl -LJO "$install_script_url"; then
      echo "Error: Failed to download Belay install script from $install_script_url."
      exit 1
  fi
else
  echo "Error: Could not access Belay install script at $install_script_url."
  echo "Please check the URL or your network connection."
  exit 1
fi

# Check if the target directory already exists before running the install script
if [ -d "$HOME/belay_klippy_module" ]; then
    echo "Directory '$HOME/belay_klippy_module' already exists."
    echo "Skipping execution of downloaded install.sh to avoid git clone error."
    echo "Assuming Belay module is already installed."
    # Clean up the downloaded script if it exists
    rm -f install.sh
else
    # Directory doesn't exist, proceed with the installation script
    echo "Running downloaded install.sh..."
    chmod +x install.sh
    ./install.sh
    rm install.sh
fi
echo "Belay module installation step finished."

# --- Add Belay to Moonraker Update Manager ---
echo "Adding Belay to Moonraker update manager..."
belay_config="
[update_manager belay]
type: git_repo
path: ~/belay_klippy_module
origin: https://github.com/Annex-Engineering/Belay.git
primary_branch: main
managed_services: klipper
info_tags:
    desc=Belay
    author=Annex Engineering
"

# Check if the belay update_manager section already exists
if grep -q "\[update_manager belay\]" "$moonraker_conf_path"; then
        echo "Belay update_manager section already exists in $moonraker_conf_path. Skipping."
else
        # Append the configuration block to moonraker.conf
        echo "" >> "$moonraker_conf_path" # Add a newline for separation
        echo "$belay_config" >> "$moonraker_conf_path"
        echo "Belay update_manager section added to $moonraker_conf_path."
fi

echo "--- Belay Installation and Configuration Finished ---"
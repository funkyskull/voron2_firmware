#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "--- Starting KlipperScreen Installation and Configuration ---"

# Define the likely path to moonraker.conf
# Adjust this path if your configuration directory is different (e.g., ~/printer_data/config)
moonraker_conf_path="${HOME}/printer_data/config/moonraker.conf"

# Check if the moonraker config file exists
if [ ! -f "$moonraker_conf_path" ]; then
        echo "Error: Moonraker configuration file not found at $moonraker_conf_path"
        echo "Please ensure Klipper and Moonraker are installed correctly or adjust the path in the script."
        exit 1
fi

# --- Add KlipperScreen to Moonraker Update Manager ---
echo "Adding KlipperScreen to Moonraker update manager..."
klipperscreen_config="
[update_manager KlipperScreen]
type: git_repo
path: ~/KlipperScreen
origin: https://github.com/KlipperScreen/KlipperScreen.git
virtualenv: ~/.KlipperScreen-env
requirements: scripts/KlipperScreen-requirements.txt
system_dependencies: scripts/system-dependencies.json
managed_services: KlipperScreen
info_tags:
    desc=KlipperScreen Touch Interface
    author=Jordan Ruthe
"

# Check if the KlipperScreen update_manager section already exists
if grep -q "\[update_manager KlipperScreen\]" "$moonraker_conf_path"; then
    echo "KlipperScreen update_manager section already exists in $moonraker_conf_path. Skipping."
else
    # Append the configuration block to moonraker.conf
    echo "" >> "$moonraker_conf_path" # Add a newline for separation
    echo "$klipperscreen_config" >> "$moonraker_conf_path"
    echo "KlipperScreen update_manager section added to $moonraker_conf_path."
fi

echo "--- Starting Moonraker Authorization Configuration ---"
echo "Configuring trusted clients in Moonraker..."
# Check if [authorization] section exists
if grep -q -E "^\s*\[authorization\]" "$moonraker_conf_path"; then
    echo "[authorization] section found."
    # Check if trusted_clients exists within the [authorization] section
    # Use awk to check between [authorization] and the next section or EOF
    if awk '/^\s*\[authorization\]/{f=1;next} /^\s*\[/{f=0} f && /^\s*trusted_clients\s*:/' "$moonraker_conf_path" | grep -q .; then
        echo "trusted_clients key found."
        # Check if 127.0.0.1 is already listed under trusted_clients
        # Use awk again to check lines between trusted_clients and the next non-indented line/section/EOF
        if awk '/^\s*trusted_clients\s*:/{f=1;next} /^\s*[^ \t]/{f=0} f && /^\s*127\.0\.0\.1\s*$/' "$moonraker_conf_path" | grep -q .; then
            echo "127.0.0.1 already in trusted_clients. Skipping."
        else
            echo "Adding 127.0.0.1 to trusted_clients."
            # Insert '    127.0.0.1' after the 'trusted_clients:' line using sed
            # This assumes the multi-line format for trusted_clients
            sed -i '/^\s*trusted_clients\s*:/a \    127.0.0.1' "$moonraker_conf_path"
            echo "127.0.0.1 added to trusted_clients."
        fi
    else
        echo "trusted_clients key not found under [authorization]. Adding key and 127.0.0.1."
        # Insert 'trusted_clients:\n    127.0.0.1' after the '[authorization]' line
        # Using two sed commands for better portability (\n in 'a' command is not standard)
        sed -i '/^\s*\[authorization\]/a trusted_clients:' "$moonraker_conf_path"
        sed -i '/^\s*trusted_clients\s*:/a \    127.0.0.1' "$moonraker_conf_path"
        echo "trusted_clients key and 127.0.0.1 added."
    fi
else
    echo "[authorization] section not found. Adding section and 127.0.0.1."
    # Append the section to the end of the file
    echo "" >> "$moonraker_conf_path" # Ensure newline separation
    echo "[authorization]" >> "$moonraker_conf_path"
    echo "trusted_clients:" >> "$moonraker_conf_path"
    echo "    127.0.0.1" >> "$moonraker_conf_path"
    echo "[authorization] section with trusted_clients 127.0.0.1 added."
fi
echo "--- Moonraker Authorization Configuration Finished ---"

# --- KlipperScreen Installation ---
echo "Installing KlipperScreen..."
cd ~
if [ -d "KlipperScreen" ]; then
    echo "KlipperScreen directory already exists. Skipping clone."
else
    git clone https://github.com/KlipperScreen/KlipperScreen.git
fi
# Check if install script exists before running
if [ -f "./KlipperScreen/scripts/KlipperScreen-install.sh" ]; then
    ./KlipperScreen/scripts/KlipperScreen-install.sh
else
    echo "KlipperScreen install script not found at ./KlipperScreen/scripts/KlipperScreen-install.sh"
    echo "Attempting KlipperScreen setup via Moonraker update manager configuration (if applicable)."
fi
echo "KlipperScreen installation complete."

echo "--- KlipperScreen Installation and Configuration Finished ---"
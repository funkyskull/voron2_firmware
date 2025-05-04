#!/bin/bash

# Stop Klipper service
echo "Stopping Klipper service..."
sudo service klipper stop

# Navigate to Klipper directory and update
echo "Updating Klipper..."
cd ~/klipper || { echo "Failed to change directory to ~/klipper"; exit 1; }
git pull

# Ensure Katapult is installed and update to date
echo "Ensuring Katapult is installed and up-to-date..."
if [ -d ~/katapult ]; then
    echo "Katapult directory found, updating..."
    cd ~/katapult || { echo "Failed to change directory to ~/katapult"; exit 1; }
    git pull || { echo "Failed to update Katapult"; exit 1; }
    cd .. # Go back to the previous directory (klipper)
else
    echo "Katapult directory not found, cloning..."
    git clone https://github.com/Arksine/katapult ~/katapult || { echo "Failed to clone Katapult"; exit 1; }
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Define the directory where make config files are stored, relative to this script's location
CONFIG_DIR="${SCRIPT_DIR}/../make_configs" # Adjust this path if needed

# Check if the config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: Configuration directory '$CONFIG_DIR' not found."
    exit 1
fi

# Check if required config files exist
required_configs=("octopus.config" "ebb2206.config" "mbb.config" "rpi.config")
for cfg in "${required_configs[@]}"; do
    if [ ! -f "$CONFIG_DIR/$cfg" ]; then
        echo "Error: Required configuration file '$CONFIG_DIR/$cfg' not found."
        exit 1
    fi
done

echo "Using configuration files from: $CONFIG_DIR"

# Build firmware for Octopus Pro board
echo "Building firmware for Octopus Pro..."
make clean KCONFIG_CONFIG="$CONFIG_DIR/octopus.config"
make menuconfig KCONFIG_CONFIG="$CONFIG_DIR/octopus.config"
make KCONFIG_CONFIG="$CONFIG_DIR/octopus.config"
read -p "Octopus Pro firmware built, please check above for any errors. Press [Enter] to continue flashing, or [Ctrl+C] to abort"

# Flash firmware to Octopus Pro board
echo "Flashing Octopus Pro firmware..."
python3 ~/katapult/scripts/flashtool.py -i can0 -f ~/klipper/out/klipper.bin -u d5c4b231d3ef
read -p "Octopus Pro firmware flashed, please check above for any errors. Press [Enter] to continue, or [Ctrl+C] to abort"

# Build firmware for EBB2206 board
echo "Building firmware for EBB2206..."
make clean KCONFIG_CONFIG="$CONFIG_DIR/ebb2206.config"
make menuconfig KCONFIG_CONFIG="$CONFIG_DIR/ebb2206.config"
make KCONFIG_CONFIG="$CONFIG_DIR/ebb2206.config"
read -p "EBB2206 firmware built, please check above for any errors. Press [Enter] to continue flashing, or [Ctrl+C] to abort"

# Flash firmware to EBB2206 board
echo "Flashing EBB2206 firmware..."
python3 ~/katapult/scripts/flashtool.py -i can0 -f ~/klipper/out/klipper.bin -u d6fba2e6c6ac
read -p "EBB2206 firmware flashed, please check above for any errors. Press [Enter] to continue, or [Ctrl+C] to abort"

# Build firmware for MBB board
echo "Building firmware for MBB..."
make clean KCONFIG_CONFIG="$CONFIG_DIR/mbb.config"
make menuconfig KCONFIG_CONFIG="$CONFIG_DIR/mbb.config"
make KCONFIG_CONFIG="$CONFIG_DIR/mbb.config"
read -p "MBB firmware built, please check above for any errors. Press [Enter] to continue flashing, or [Ctrl+C] to abort"

# Flash firmware to MBB board
echo "Flashing MBB firmware..."
python3 ~/katapult/scripts/flashtool.py -i can0 -f ~/klipper/out/klipper.bin -u 66b75cee8d57
read -p "MBB firmware flashed, please check above for any errors. Press [Enter] to continue, or [Ctrl+C] to abort"

# Ensure the klipper-mcu service for RPi is installed and enabled
echo "Ensuring RPi klipper-mcu service is installed and enabled..."
if systemctl is-active --quiet klipper-mcu; then
    echo "klipper-mcu service installed and active."
else
    echo "klipper-mcu service is not installed and active, installing..."
    # Check if the klipper-mcu.service file exists in the scripts directory
    if [ -f ~/klipper/scripts/klipper-mcu.service ]; then
        sudo cp ~/klipper/scripts/klipper-mcu.service /etc/systemd/system/
        sudo systemctl enable klipper-mcu.service
    else
        echo "Warning: klipper-mcu.service not found in ~/klipper/scripts/. Skipping service installation."
    fi    
fi

# Build firmware for Raspberry Pi MCU
echo "Building firmware for Raspberry Pi MCU..."
make clean KCONFIG_CONFIG="$CONFIG_DIR/rpi.config"
make menuconfig KCONFIG_CONFIG="$CONFIG_DIR/rpi.config"
make KCONFIG_CONFIG="$CONFIG_DIR/rpi.config"
read -p "RPi firmware built, please check above for any errors. Press [Enter] to continue flashing, or [Ctrl+C] to abort"

# Flash firmware for Raspberry Pi MCU
echo "Flashing RPi firmware..."
make flash KCONFIG_CONFIG="$CONFIG_DIR/rpi.config"

# Start Klipper service
echo "Starting Klipper service..."
sudo service klipper start

echo "Firmware update process complete."

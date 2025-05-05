#!/bin/bash
# This script configures a CAN interface on a raspberry pi system.

echo "--- Configuring CAN bus interface (can0) ---"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root using sudo."
  exit 1
fi

CAN_INTERFACE_CONF="/etc/network/interfaces.d/can0"
CONFIG_DIR="/etc/network/interfaces.d"

# Check if the configuration directory exists, create if not
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Directory $CONFIG_DIR does not exist. Creating it..."
    mkdir -p "$CONFIG_DIR" || { echo "Failed to create directory $CONFIG_DIR"; exit 1; }
fi

# Check if the can0 interface configuration file already exists
if [ -f "$CAN_INTERFACE_CONF" ]; then
    echo "CAN interface configuration file '$CAN_INTERFACE_CONF' already exists."
    echo "Skipping creation."
    # Optional: Ask if user wants to overwrite?
    # read -p "Overwrite existing configuration? (y/N): " overwrite
    # if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
    #     echo "Exiting without changes."
    #     exit 0
    # fi
else
    echo "Creating CAN interface configuration file: $CAN_INTERFACE_CONF..."
    # Create the can0 interface file
    cat > "$CAN_INTERFACE_CONF" << EOF
allow-hotplug can0
iface can0 can static
    bitrate 1000000
    up ifconfig \$IFACE txqueuelen 1024
EOF
    echo "Created $CAN_INTERFACE_CONF."
    echo "IMPORTANT: A reboot might be required for changes to take full effect."
    read -p "Reboot now? (y/N): " confirm_reboot
    if [[ "$confirm_reboot" =~ ^[Yy]$ ]]; then
      echo "Rebooting..."
      reboot
    else
      echo "Please reboot the Raspberry Pi manually ('sudo reboot') if needed."
    fi
fi

# Attempt to bring up the interface now (might require reboot depending on system state)
echo "Attempting to bring up can0 interface..."
if sudo ifup can0; then
    echo "can0 interface brought up successfully."
else
    echo "Failed to bring up can0 interface. A reboot may be required."
fi


exit 0
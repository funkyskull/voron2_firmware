!/bin/bash
# This script configures a CAN interface on a raspberry pi system.

echo "--- Enabling CAN bus on Raspberry Pi ---"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root using sudo."
  exit 1
fi

CAN_INTERFACE_CONF="/etc/network/interfaces.d/can0"

# Create the can0 interface file
cat > "$CAN_INTERFACE_CONF" << EOF
allow-hotplug can0
iface can0 can static
    bitrate 1000000
    up ifconfig $IFACE txqueuelen 1024
EOF

echo "Created $CAN_INTERFACE_CONF."
echo "IMPORTANT: A reboot is required for these changes to take effect."
read -p "Reboot now? (y/N): " confirm_reboot
if [[ "$confirm_reboot" =~ ^[Yy]$ ]]; then
  echo "Rebooting..."
  reboot
else
  echo "Please reboot the Raspberry Pi manually ('sudo reboot') to activate the CAN bus."
fi

exit 0
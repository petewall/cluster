#!/bin/bash

# This is meant to be run on the laptop just after the SD card has been imaged

WIRELESS_SSID=$(jq -r '.["wifi-ssid"]' ../secrets/pipeline-creds.json)
WIRELESS_PASSWORD=$(jq -r '.["wifi-password"]' ../secrets/pipeline-creds.json)

if [ ! -d /Volumes/system-boot/ ]; then
    echo Check that the SD card is mounted?
    exit 1
fi

# Initialize the WiFi settings
NETWORK_FILE=/Volumes/system-boot/network-config
yq \
    --arg ssid "${WIRELESS_SSID}" \
    --arg pass "${WIRELESS_PASSWORD}" \
'. * {
  "wifis": {
    "wlan0": {
      "dhcp4": true,
      "optional": true,
      "access-points": {
        ($ssid): {
          "password": $pass
        }
      }
    }
  }
}' "${NETWORK_FILE}" --yaml-output | sed -e "s/password: ${WIRELESS_PASSWORD}/password: \"${WIRELESS_PASSWORD}\"/" > "${NETWORK_FILE}.new"
mv "${NETWORK_FILE}.new" "${NETWORK_FILE}"

# Enable cgroups
CMDLINE_FILE=/Volumes/system-boot/cmdline.txt
if ! grep --quiet 'cgroup_enable' "${CMDLINE_FILE}" ; then
    sed -i -e 's/$/ cgroup_memory=1 cgroup_enable=memory/' "${CMDLINE_FILE}"
fi

echo "Done!"

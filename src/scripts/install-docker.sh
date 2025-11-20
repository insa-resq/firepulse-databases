#!/bin/sh

# This script install Docker on the host if it is not already present.

set -eu

# Ensure script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root"  >&2
   exit 1
fi

# Ensure Debian-based OS
if [ ! -f /etc/debian_version ]; then
    echo "This script requires a Debian-based OS." >&2
    exit 1
fi

# Check if Docker is installed
if command -v docker > /dev/null 2>&1; then
    echo "Docker is already installed. Skipping installation."
    exit 0
fi

# Install Docker if not already installed

echo "Docker not found. Installing Docker..."

# Load OS information variables

OS_RELEASE_FILE="/etc/os-release"
if [ ! -f "$OS_RELEASE_FILE" ]; then
    echo "$OS_RELEASE_FILE not found. OS environment variables not loaded." >&2
    exit 1
fi

. "$OS_RELEASE_FILE"

if [ -z "${ID:-}" ]; then
    echo "ID not defined in $OS_RELEASE_FILE." >&2
    exit 1
fi
if [ -z "${VERSION_CODENAME:-}" ]; then
    echo "VERSION_CODENAME not defined in $OS_RELEASE_FILE." >&2
    exit 1
fi

# Add Docker's official GPG key:
apt-get update
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/$ID/gpg" -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/$ID
Suites: $VERSION_CODENAME
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Install Docker Engine and containerd
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Make sure Docker is installed and started
if command -v systemctl > /dev/null 2>&1; then
    systemctl enable --now docker
else
    echo "systemctl not found. Not starting Docker service automatically."
fi

echo "Docker installed successfully."

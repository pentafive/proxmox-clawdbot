#!/usr/bin/env bash

# Clawdbot LXC Installation Script (Standalone)
# Run on Proxmox host: bash <(curl -fsSL URL)

set -e

# Colors
RD="\033[01;31m"
GN="\033[1;32m"
YW="\033[33m"
BL="\033[36m"
CL="\033[m"

# Defaults
CT_NAME="clawdbot"
CT_ID=""
CT_CORES=4
CT_RAM=4096
CT_DISK=16
CT_STORAGE=""
CT_BRIDGE="vmbr0"
CT_OS="debian-12-standard"

echo -e "${BL}
   _____ _                    _ _           _   
  / ____| |                  | | |         | |  
 | |    | | __ ___      _____| | |__   ___ | |_ 
 | |    | |/ _\` \ \ /\ / / _ \ | '_ \ / _ \| __|
 | |____| | (_| |\ V  V /  __/ | |_) | (_) | |_ 
  \_____|_|\__,_| \_/\_/ \___|_|_.__/ \___/ \__|
${CL}"
echo -e "${GN}Clawdbot LXC Installer${CL}\n"

# Check if running on Proxmox
if ! command -v pct &> /dev/null; then
    echo -e "${RD}Error: This script must be run on a Proxmox host${CL}"
    exit 1
fi

# Get next available CT ID
if [[ -z "$CT_ID" ]]; then
    CT_ID=$(pvesh get /cluster/nextid)
fi

echo -e "${YW}Configuration:${CL}"
echo -e "  Container ID: ${GN}$CT_ID${CL}"
echo -e "  Name: ${GN}$CT_NAME${CL}"
echo -e "  Cores: ${GN}$CT_CORES${CL}"
echo -e "  RAM: ${GN}${CT_RAM}MB${CL}"
echo -e "  Disk: ${GN}${CT_DISK}GB${CL}"
echo ""

read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Detect storage if not set
if [[ -z "$CT_STORAGE" ]]; then
    # Try common storage names
    for storage in local-lvm local-zfs local; do
        if pvesm status | grep -q "^$storage "; then
            CT_STORAGE="$storage"
            break
        fi
    done
    # If still empty, get first available storage that supports rootdir
    if [[ -z "$CT_STORAGE" ]]; then
        CT_STORAGE=$(pvesm status --content rootdir 2>/dev/null | awk 'NR==2 {print $1}')
    fi
    if [[ -z "$CT_STORAGE" ]]; then
        echo -e "${RD}Error: No suitable storage found${CL}"
        echo "Available storage:"
        pvesm status
        exit 1
    fi
fi

echo -e "  Storage: ${GN}$CT_STORAGE${CL}"

# Download template if needed
echo -e "\n${YW}Checking template...${CL}"
TEMPLATE=$(pveam available --section system | grep "$CT_OS" | tail -1 | awk '{print $2}')
if [[ -z "$TEMPLATE" ]]; then
    echo -e "${RD}Template $CT_OS not found${CL}"
    exit 1
fi

if ! pveam list local | grep -q "$TEMPLATE"; then
    echo -e "${YW}Downloading template...${CL}"
    pveam download local "$TEMPLATE"
fi

# Create container
echo -e "\n${YW}Creating container...${CL}"
pct create "$CT_ID" "local:vztmpl/$TEMPLATE" \
    --hostname "$CT_NAME" \
    --cores "$CT_CORES" \
    --memory "$CT_RAM" \
    --rootfs "${CT_STORAGE}:${CT_DISK}" \
    --net0 "name=eth0,bridge=${CT_BRIDGE},ip=dhcp" \
    --features "nesting=1,fuse=1" \
    --unprivileged 1 \
    --onboot 1

# Start container
echo -e "${YW}Starting container...${CL}"
pct start "$CT_ID"
sleep 5

# Run install script inside container
echo -e "\n${YW}Installing Clawdbot...${CL}"
pct exec "$CT_ID" -- bash -c '
set -e

echo "Updating packages..."
apt update && apt upgrade -y

echo "Installing dependencies..."
apt install -y curl gnupg build-essential git sshfs ca-certificates

echo "Fixing pam_systemd for fast SSH..."
sed -i "s/^\(session.*pam_systemd.so\)/#\1/" /etc/pam.d/common-session

echo "Enabling fuse..."
sed -i "s/#user_allow_other/user_allow_other/" /etc/fuse.conf 2>/dev/null || true

echo "Installing Node.js 22..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

echo "Installing Clawdbot..."
npm install -g clawdbot

echo "Installing Matrix dependencies..."
cd /usr/lib/node_modules/clawdbot && npm install matrix-bot-sdk 2>/dev/null || true

echo "Installing Gemini CLI..."
npm install -g @google/gemini-cli

echo "Installing fastfetch..."
curl -fsSL https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb -o /tmp/fastfetch.deb
dpkg -i /tmp/fastfetch.deb
rm /tmp/fastfetch.deb
echo "fastfetch" >> /root/.bashrc

echo "Creating config directory..."
mkdir -p /opt/clawdbot/workspace

cat <<EOF >/opt/clawdbot/config.yaml
# Clawdbot Configuration
# Documentation: https://docs.clawd.bot

# anthropic:
#   apiKey: "your-api-key"

gateway:
  port: 3003
  host: "0.0.0.0"

webchat:
  enabled: true

workspace: /opt/clawdbot/workspace

logging:
  level: info
EOF

echo "Creating systemd service..."
cat <<EOF >/etc/systemd/system/clawdbot.service
[Unit]
Description=Clawdbot AI Assistant Gateway
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/clawdbot
ExecStart=/usr/bin/clawdbot gateway start --config /opt/clawdbot/config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable clawdbot

echo "Cleaning up..."
apt autoremove -y
apt autoclean

echo "Done!"
'

# Get IP
CT_IP=$(pct exec "$CT_ID" -- hostname -I | awk '{print $1}')

echo -e "\n${GN}========================================${CL}"
echo -e "${GN}  Clawdbot installed successfully!${CL}"
echo -e "${GN}========================================${CL}"
echo -e ""
echo -e "  Container ID: ${YW}$CT_ID${CL}"
echo -e "  IP Address:   ${YW}$CT_IP${CL}"
echo -e "  Web UI:       ${YW}http://$CT_IP:3003${CL}"
echo -e ""
echo -e "  ${YW}Next steps:${CL}"
echo -e "  1. pct enter $CT_ID"
echo -e "  2. Edit /opt/clawdbot/config.yaml (add API key)"
echo -e "  3. systemctl start clawdbot"
echo -e "  4. gemini (to authenticate)"
echo -e ""

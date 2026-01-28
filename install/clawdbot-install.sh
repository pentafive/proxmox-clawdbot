#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: JD (pentafive)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/clawdbot/clawdbot

# Import Functions and Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  git \
  sshfs
msg_ok "Installed Dependencies"

msg_info "Configuring LXC Optimizations"
# Fix slow SSH login (pam_systemd times out in LXC)
sed -i 's/^\(session.*pam_systemd.so\)/#\1/' /etc/pam.d/common-session
# Enable user_allow_other for SSHFS mounts
sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf
msg_ok "Configured LXC Optimizations"

# Use helper function for Node.js
NODE_VERSION="22" setup_nodejs

msg_info "Installing Clawdbot"
$STD npm install -g clawdbot
msg_ok "Installed Clawdbot"

msg_info "Installing Matrix Dependencies"
cd /usr/lib/node_modules/clawdbot && $STD npm install matrix-bot-sdk
msg_ok "Installed Matrix Dependencies"

msg_info "Installing Gemini CLI"
$STD npm install -g @google/gemini-cli
msg_ok "Installed Gemini CLI"

msg_info "Installing Claude Code"
$STD npm install -g @anthropic-ai/claude-code
msg_ok "Installed Claude Code"

msg_info "Installing fastfetch"
curl -fsSL https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb -o /tmp/fastfetch.deb
$STD dpkg -i /tmp/fastfetch.deb
rm -f /tmp/fastfetch.deb
echo 'fastfetch' >> /root/.bashrc
msg_ok "Installed fastfetch"

# Optional: Cockpit web admin
read -r -p "Would you like to install Cockpit web admin? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  msg_info "Installing Cockpit"
  $STD apt install -y cockpit
  systemctl enable -q --now cockpit.socket
  msg_ok "Installed Cockpit (https://IP:9090)"
fi

get_lxc_ip

msg_info "Creating Configuration"
mkdir -p /opt/clawdbot/workspace
cat <<EOF >/opt/clawdbot/config.yaml
# Clawdbot Configuration
# Documentation: https://docs.clawd.bot

# LLM Provider Configuration
# anthropic:
#   apiKey: "your-anthropic-api-key"
# openai:
#   apiKey: "your-openai-api-key"

# Gateway Settings
gateway:
  port: 3003
  host: "0.0.0.0"

# Webchat (built-in web interface)
webchat:
  enabled: true

# Workspace
workspace: /opt/clawdbot/workspace

# Logging
logging:
  level: info

# Channels (configure as needed)
# channels:
#   matrix:
#     enabled: true
#     homeserver: "https://matrix.example.org"
#     userId: "@bot:example.org"
#     accessToken: "your-access-token"
#     encryption: true
EOF
msg_ok "Created Configuration"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/clawdbot.service
[Unit]
Description=Clawdbot AI Assistant Gateway
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/clawdbot
Environment=CLAWDBOT_CONFIG=/opt/clawdbot/config.yaml
ExecStart=/usr/bin/clawdbot gateway --bind lan --allow-unconfigured
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable -q clawdbot
systemctl start clawdbot
sleep 2
if systemctl is-active --quiet clawdbot; then
  msg_ok "Created Service (running)"
else
  msg_warn "Service created but not running - configure API key first"
fi

motd_ssh
customize
cleanup_lxc

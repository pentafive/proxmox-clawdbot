#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: JD (pentafive)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/clawdbot/clawdbot

APP="Clawdbot"
var_tags="${var_tags:-ai;assistant}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /etc/systemd/system/clawdbot.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(npm show clawdbot version 2>/dev/null)
  CURRENT=$(clawdbot --version 2>/dev/null | head -1 | grep -oP '[\d.]+' || echo "0.0.0")

  if [[ "${RELEASE}" != "${CURRENT}" ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop clawdbot
    msg_ok "Stopped ${APP}"

    msg_info "Updating ${APP} to v${RELEASE}"
    $STD npm update -g clawdbot
    msg_ok "Updated ${APP}"

    msg_info "Updating Gemini CLI"
    $STD npm update -g @google/gemini-cli
    msg_ok "Updated Gemini CLI"

    msg_info "Starting ${APP}"
    systemctl start clawdbot
    msg_ok "Started ${APP}"

    msg_ok "Updated successfully to v${RELEASE}"
  else
    msg_ok "No update required. ${APP} is already at v${CURRENT}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3003${CL}"
echo ""
echo -e "${INFO}${YW} Post-install:${CL}"
echo -e "${TAB}• Edit config: ${BGN}/opt/clawdbot/config.yaml${CL}"
echo -e "${TAB}• Or run: ${BGN}clawdbot configure${CL}"
echo -e "${TAB}• Authenticate Gemini: ${BGN}gemini${CL}"
echo ""
echo -e "${INFO}${YW} Documentation: ${BGN}https://docs.clawd.bot${CL}"

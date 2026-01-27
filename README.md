# Clawdbot Proxmox VE Helper Script

This is a submission for the [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE) project.

## What is Clawdbot?

**Clawdbot** is an AI-powered personal assistant that runs as a background daemon, bridging Claude and other LLMs to:
- Messaging platforms (Signal, Telegram, Discord, Slack, iMessage)
- Smart home systems (Home Assistant)
- Developer tools (browser automation, shell access, MCP servers)

It's designed for homelabbers and power users who want an always-on AI assistant with full system access.

**Key Features:**
- Multi-channel messaging support
- Cron scheduling and reminders
- Browser automation (Playwright)
- MCP (Model Context Protocol) integration
- Built-in web interface
- Persistent memory across sessions

## Files

| File | Purpose |
|------|---------|
| `ct/clawdbot.sh` | Container creation script (runs on Proxmox host) |
| `install/clawdbot-install.sh` | Installation script (runs inside container) |
| `json/clawdbot.json` | Metadata for the web interface |

## Installation

After merging, users can install with:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/clawdbot.sh)"
```

## Post-Installation

1. Edit `/opt/clawdbot/config.yaml` to add your Anthropic API key
2. Configure messaging channels as needed
3. Access the web interface at `http://<IP>:3003`

## Resources

- **Documentation:** https://docs.clawd.bot
- **Source:** https://github.com/clawdbot/clawdbot
- **Discord:** https://discord.com/invite/clawd

## Container Defaults

- **CPU:** 2 cores
- **RAM:** 2048 MB
- **Disk:** 8 GB
- **OS:** Debian 13
- **Port:** 3003 (web interface)

## Author

- **JD** (pentafive) - https://github.com/pentafive

# Proxmox Clawdbot LXC Script

Proxmox VE Helper Script for deploying [Clawdbot](https://github.com/clawdbot/clawdbot) AI Assistant in an LXC container.

## Quick Start

Run on your Proxmox host:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/pentafive/proxmox-clawdbot/main/ct/clawdbot.sh)"
```

## Features

- **Clawdbot** - AI-powered personal assistant gateway
- **Gemini CLI** - Google AI command-line interface
- **Matrix E2EE** - Encrypted Matrix messaging support
- **fastfetch** - System info on login
- **LXC optimizations** - Fast SSH, SSHFS/fuse support

## Container Defaults

| Resource | Value |
|----------|-------|
| CPU | 4 cores |
| RAM | 4096 MB |
| Disk | 16 GB |
| OS | Debian 12 |
| Port | 3003 |

## Post-Installation

1. Edit config: `/opt/clawdbot/config.yaml`
2. Add your Anthropic/OpenAI API key
3. Or run: `clawdbot configure` for interactive setup
4. Authenticate Gemini: `gemini`

## Documentation

- **Clawdbot Docs**: https://docs.clawd.bot
- **Source**: https://github.com/clawdbot/clawdbot
- **Discord**: https://discord.com/invite/clawd

## Community Scripts Compatibility

This script follows the [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE) format and can be used standalone or submitted upstream.

---

**Author:** JD (pentafive)
**License:** MIT

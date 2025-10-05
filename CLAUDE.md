# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a utility tool for launching Claude Code through HTTP/SOCKS5 proxies with automatic credential management. The project consists of a single bash script that can be installed globally.

## Architecture

The codebase is a standalone bash script (`init_claude.sh`) that:

1. **Credential Management**: Stores proxy credentials in `.claude_proxy_credentials` (chmod 600, git-ignored)
2. **Proxy Configuration**: Sets environment variables (HTTPS_PROXY, HTTP_PROXY, NO_PROXY) for Claude Code
3. **Global Installation**: Creates symlink at `/usr/local/bin/init_claude` for system-wide access
4. **Proxy Detection**: Prioritizes global Claude Code installation over local installations

### Key Components

- **Proxy URL Parsing** (lines 66-103): Extracts protocol, username, password, host, port from URLs
- **Credential Persistence** (lines 108-145): Saves/loads proxy settings from `.claude_proxy_credentials`
- **Proxy Testing** (lines 248-258): Validates connectivity via curl before launching
- **Claude Detection** (lines 346-392): Finds global Claude Code binary, avoiding local npm installations

## Common Commands

### Installation
```bash
# Install globally (creates /usr/local/bin/init_claude)
sudo ./init_claude.sh --install

# Uninstall
sudo init_claude --uninstall
```

### Usage
```bash
# Launch with saved credentials (interactive prompt if none exist)
init_claude

# Set proxy directly
init_claude --proxy http://user:pass@host:port

# Test proxy without launching Claude
init_claude --test

# Clear saved credentials
init_claude --clear

# Skip connectivity test
init_claude --no-test

# Pass arguments to Claude Code
init_claude -- --model claude-3-opus
```

## Development Notes

### Proxy URL Format
Supported formats: `http://`, `https://`, `socks5://`

Pattern: `protocol://[username:password@]host:port`

Examples:
- `http://alice:secret@127.0.0.1:8118`
- `socks5://user:pass@proxy.example.com:1080`

### Security Considerations
- Credentials file has 600 permissions (owner read/write only)
- Passwords are masked in output by default (use `--show-password` to reveal)
- The credentials file is automatically excluded from git

### Script Behavior
- Uses `set -euo pipefail` for strict error handling
- Follows symlinks to resolve the script's actual directory
- Prioritizes global Claude Code installations (`/usr/local/bin/claude`, `/usr/bin/claude`) over local `node_modules`
- Warns if local Claude installation detected and attempts to find global installation

### Testing
No automated tests exist. Test manually:
```bash
# Test proxy connectivity
init_claude --test

# Test full flow
init_claude --proxy http://test:test@127.0.0.1:8118 --no-test
```

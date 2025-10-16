# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a utility tool for launching Claude Code through HTTP/SOCKS5 proxies with automatic credential management. The project consists of a single bash script that can be installed globally.

## Architecture

The codebase is a standalone bash script (`init_claude.sh`) that:

1. **Credential Management**: Stores proxy credentials in `.claude_proxy_credentials` (chmod 600, git-ignored)
2. **Proxy Configuration**: Sets environment variables (HTTPS_PROXY, HTTP_PROXY, NO_PROXY) for Claude Code
3. **Git Proxy Management**: Automatically disables proxy for git operations while keeping it enabled for Claude Code
4. **Global Installation**: Creates symlink at `/usr/local/bin/init_claude` for system-wide access
5. **Proxy Detection**: Prioritizes global Claude Code installation over local installations

### Key Components

- **Proxy URL Parsing** (lines 66-103): Extracts protocol, username, password, host, port from URLs
- **Credential Persistence** (lines 166-203): Saves/loads proxy settings from `.claude_proxy_credentials`
- **Git Proxy Management** (lines 290-349): Automatically saves/restores git proxy settings
  - `save_git_proxy_settings()`: Backs up current git proxy config
  - `configure_git_no_proxy()`: Disables proxy for git operations
  - `restore_git_proxy()`: Restores original git proxy settings
- **Proxy Configuration** (lines 274-288): Sets environment variables and configures git
- **Proxy Testing** (lines 391-403): Validates connectivity via curl before launching
- **Dependency Installation** (lines 426-570): Auto-installs Node.js, npm, and Claude Code if missing
- **Claude Detection** (lines 597-643): Finds global Claude Code binary, avoiding local npm installations

## Common Commands

### Installation
```bash
# Install globally (creates /usr/local/bin/init_claude)
# Automatically checks and installs dependencies:
# - Node.js and npm (if missing)
# - Claude Code (if missing)
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

# Restore git proxy settings from backup
init_claude --restore-git-proxy

# Launch without proxy (also restores git proxy if backup exists)
init_claude --no-proxy

# Skip connectivity test
init_claude --no-test

# Pass arguments to Claude Code
init_claude -- --model claude-3-opus

# Skip permission checks (use with caution)
init_claude --dangerously-skip-permissions
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
- **NVM Support**: Automatically detects and uses Claude Code installed via NVM
  - Searches for standard `claude` binary
  - Handles temporary npm binaries (`.claude-*`)
  - Falls back to direct `cli.js` execution if binaries not found
  - Supports temporary installation folders (`.claude-code-*`)
- Prioritizes NVM installations over system installations
- Warns if local Claude installation detected and attempts to find global installation

### Dependency Installation
During `--install`, the script automatically checks and installs missing dependencies:

1. **Node.js and npm** (if missing):
   - Uses NodeSource official repository (Node.js 18 LTS)
   - Command: `curl -fsSL https://deb.nodesource.com/setup_18.x | bash -`
   - Then: `apt-get install -y nodejs`
   - Prompts for confirmation before installing

2. **Claude Code** (if missing):
   - Installs globally via npm
   - Command: `npm install -g @anthropic-ai/claude-code`
   - Prompts for confirmation before installing

3. **Installation Flow**:
   - Checks npm → if missing, offers to install Node.js
   - Checks Claude Code → if missing, offers to install
   - Only proceeds with script installation if dependencies are satisfied
   - Can skip dependency installation but warns about missing requirements

### Git and Proxy Considerations

**Automatic Git Proxy Management:**

When you configure a proxy for Claude Code, the script automatically disables proxy for git to prevent HTTPS CONNECT issues that cause `git push` to fail.

**How it works:**
1. When proxy is configured, the script:
   - Saves your current git proxy settings to `.claude_git_proxy_backup`
   - Sets git's `http.proxy` and `https.proxy` to empty strings (bypasses proxy)
   - Configures environment variables for Claude Code (HTTPS_PROXY, HTTP_PROXY)

2. Git operations (push/pull/fetch) will work directly without proxy
3. Claude Code will still use the configured proxy

**Restore git proxy settings:**
```bash
# Restore original git proxy configuration
init_claude --restore-git-proxy
```

**Manual git proxy management:**
```bash
# Check current git proxy settings
git config --global --get http.proxy
git config --global --get https.proxy

# Manually disable git proxy
git config --global http.proxy ""
git config --global https.proxy ""

# Manually enable git proxy
git config --global http.proxy "http://proxy:port"
git config --global https.proxy "http://proxy:port"
```

**Files:**
- `.claude_proxy_credentials` - Proxy credentials for Claude Code (chmod 600)
- `.claude_git_proxy_backup` - Backup of git proxy settings (chmod 600, auto-deleted after restore)

### Testing
No automated tests exist. Test manually:
```bash
# Test proxy connectivity
init_claude --test

# Test full flow
init_claude --proxy http://test:test@127.0.0.1:8118 --no-test
```

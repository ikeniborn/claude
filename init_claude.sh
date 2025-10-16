#!/bin/bash

#######################################
# init_claude.sh - Initialize Claude Code with HTTP Proxy
# Version: 2.0
# Description: Auto-configure proxy settings and launch Claude Code
#              Stores credentials for reuse
#######################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Constants
# Resolve script directory (follows symlinks)
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
CREDENTIALS_FILE="${SCRIPT_DIR}/.claude_proxy_credentials"
GIT_BACKUP_FILE="${SCRIPT_DIR}/.claude_git_proxy_backup"

#######################################
# Print colored message
#######################################
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

#######################################
# Validate proxy URL format
#######################################
validate_proxy_url() {
    local url=$1

    # Regex: http(s)://[user:pass@]host:port
    if [[ ! "$url" =~ ^(http|https|socks5)://.*:[0-9]+$ ]]; then
        return 1
    fi

    return 0
}

#######################################
# Parse proxy URL and extract components
#######################################
parse_proxy_url() {
    local url=$1

    # Extract protocol
    local protocol=$(echo "$url" | grep -oP '^[^:]+')

    # Extract everything after protocol://
    local remainder=$(echo "$url" | sed 's|^[^:]*://||')

    # Check if credentials present (contains @)
    if [[ "$remainder" =~ @ ]]; then
        # Extract user:pass
        local credentials=$(echo "$remainder" | grep -oP '^[^@]+')
        local username=$(echo "$credentials" | cut -d':' -f1)
        local password=$(echo "$credentials" | cut -d':' -f2-)

        # Extract host:port after @
        local hostport=$(echo "$remainder" | sed 's|^[^@]*@||')
        local host=$(echo "$hostport" | cut -d':' -f1)
        local port=$(echo "$hostport" | cut -d':' -f2)

        echo "protocol=$protocol"
        echo "username=$username"
        echo "password=$password"
        echo "host=$host"
        echo "port=$port"
    else
        # No credentials
        local host=$(echo "$remainder" | cut -d':' -f1)
        local port=$(echo "$remainder" | cut -d':' -f2)

        echo "protocol=$protocol"
        echo "username="
        echo "password="
        echo "host=$host"
        echo "port=$port"
    fi
}

#######################################
# Detect if NVM is installed and active
#######################################
detect_nvm() {
	# Check if NVM_DIR is set and nvm.sh exists
	if [[ -n "${NVM_DIR:-}" ]] && [[ -s "${NVM_DIR}/nvm.sh" ]]; then
		return 0
	fi

	# Check if npm/node is from NVM by examining the path
	local npm_path=$(command -v npm 2>/dev/null)
	if [[ -n "$npm_path" ]] && [[ "$npm_path" == *".nvm"* ]]; then
		return 0
	fi

	local node_path=$(command -v node 2>/dev/null)
	if [[ -n "$node_path" ]] && [[ "$node_path" == *".nvm"* ]]; then
		return 0
	fi

	return 1
}

#######################################
# Get Claude path from NVM environment
#######################################
get_nvm_claude_path() {
	# Try to find claude in active NVM node version
	if [[ -n "${NVM_DIR:-}" ]]; then
		# Get current node version
		local current_node=""
		if command -v nvm &> /dev/null; then
			current_node=$(nvm current 2>/dev/null)
		fi

		# Check if valid version
		if [[ -n "$current_node" ]] && [[ "$current_node" != "none" ]] && [[ "$current_node" != "system" ]]; then
			local nvm_bin="${NVM_DIR}/versions/node/$current_node/bin"
			local nvm_lib="${NVM_DIR}/versions/node/$current_node/lib/node_modules/@anthropic-ai"

			# First try standard 'claude' binary
			if [[ -x "$nvm_bin/claude" ]]; then
				echo "$nvm_bin/claude"
				return 0
			fi

			# Then try temporary .claude-* binaries
			if ls "$nvm_bin/.claude-"* &>/dev/null; then
				local temp_claude=$(ls "$nvm_bin/.claude-"* 2>/dev/null | head -n 1)
				if [[ -x "$temp_claude" ]]; then
					echo "$temp_claude"
					return 0
				fi
			fi

			# If binaries not found, try to find cli.js in node_modules (including temp folders)
			if [[ -d "$nvm_lib" ]]; then
				# Try standard claude-code folder first
				if [[ -f "$nvm_lib/claude-code/cli.js" ]]; then
					echo "node $nvm_lib/claude-code/cli.js"
					return 0
				fi

				# Then try temporary .claude-code-* folders
				local temp_cli=$(find "$nvm_lib" -maxdepth 2 -name "cli.js" -path "*/.claude-code-*/cli.js" 2>/dev/null | head -n 1)
				if [[ -n "$temp_cli" ]] && [[ -f "$temp_cli" ]]; then
					echo "node $temp_cli"
					return 0
				fi
			fi
		fi
	fi

	# Alternative: use npm prefix to find global bin
	local npm_prefix=$(npm prefix -g 2>/dev/null)
	if [[ -n "$npm_prefix" ]] && [[ "$npm_prefix" == *".nvm"* ]]; then
		# First try standard 'claude' binary
		if [[ -x "$npm_prefix/bin/claude" ]]; then
			echo "$npm_prefix/bin/claude"
			return 0
		fi

		# Then try temporary .claude-* binaries
		if ls "$npm_prefix/bin/.claude-"* &>/dev/null; then
			local temp_claude=$(ls "$npm_prefix/bin/.claude-"* 2>/dev/null | head -n 1)
			if [[ -x "$temp_claude" ]]; then
				echo "$temp_claude"
				return 0
			fi
		fi

		# If binaries not found, try to find cli.js in node_modules
		local npm_lib="$npm_prefix/lib/node_modules/@anthropic-ai"
		if [[ -d "$npm_lib" ]]; then
			# Try standard claude-code folder first
			if [[ -f "$npm_lib/claude-code/cli.js" ]]; then
				echo "node $npm_lib/claude-code/cli.js"
				return 0
			fi

			# Then try temporary .claude-code-* folders
			local temp_cli=$(find "$npm_lib" -maxdepth 2 -name "cli.js" -path "*/.claude-code-*/cli.js" 2>/dev/null | head -n 1)
			if [[ -n "$temp_cli" ]] && [[ -f "$temp_cli" ]]; then
				echo "node $temp_cli"
				return 0
			fi
		fi
	fi

	return 1
}

#######################################
# Save credentials to file
#######################################
save_credentials() {
    local proxy_url=$1

    # Create credentials file with restricted permissions
    touch "$CREDENTIALS_FILE"
    chmod 600 "$CREDENTIALS_FILE"

    # Save URL
    echo "$proxy_url" > "$CREDENTIALS_FILE"

    print_success "Credentials saved to: $CREDENTIALS_FILE"
}

#######################################
# Load credentials from file
#######################################
load_credentials() {
    if [[ ! -f "$CREDENTIALS_FILE" ]]; then
        return 1
    fi

    # Read proxy URL from file
    local proxy_url
    proxy_url=$(cat "$CREDENTIALS_FILE")

    if [[ -z "$proxy_url" ]]; then
        return 1
    fi

    # Validate URL
    if ! validate_proxy_url "$proxy_url"; then
        print_warning "Saved credentials are invalid, will prompt for new URL"
        return 1
    fi

    echo "$proxy_url"
    return 0
}

#######################################
# Prompt for proxy URL
#######################################
prompt_proxy_url() {
    local saved_url

    # Check if credentials exist
    if saved_url=$(load_credentials); then
        print_info "Saved proxy found" >&2
        echo "" >&2
        # Hide password in display
        local display_url=$(echo "$saved_url" | sed -E 's|://([^:]+):([^@]+)@|://\1:****@|')
        echo "  URL: $display_url" >&2
        echo "" >&2

        local use_saved=""
        if [ -t 0 ]; then
            read -p "Use saved proxy? (Y/n): " use_saved >&2
        else
            # Non-interactive mode: auto-use saved proxy
            use_saved="y"
        fi

        if [[ -z "$use_saved" ]] || [[ "$use_saved" =~ ^[Yy] ]]; then
            echo "$saved_url"
            return 0
        fi
    fi

    # Prompt for new URL
    echo "" >&2
    print_info "Enter HTTP proxy URL" >&2
    echo "" >&2
    echo "Format: http://username:password@host:port" >&2
    echo "Example: http://alice:secret123@127.0.0.1:8118" >&2
    echo "" >&2
    echo "Supported protocols: http, socks5" >&2
    echo "" >&2

    while true; do
        local proxy_url=""
        if [ -t 0 ]; then
            read -p "Proxy URL: " proxy_url >&2
        else
            # Non-interactive mode: cannot prompt for new URL
            print_error "Cannot prompt for proxy URL in non-interactive mode" >&2
            echo "Use: init_claude --proxy <url>" >&2
            exit 1
        fi

        if [[ -z "$proxy_url" ]]; then
            print_error "URL cannot be empty" >&2
            continue
        fi

        if ! validate_proxy_url "$proxy_url"; then
            print_error "Invalid URL format" >&2
            echo "Expected: protocol://[user:pass@]host:port" >&2
            continue
        fi

        echo "$proxy_url"
        return 0
    done
}

#######################################
# Configure proxy from URL
#######################################
configure_proxy_from_url() {
    local proxy_url=$1

    # Set environment variables
    export HTTPS_PROXY="$proxy_url"
    export HTTP_PROXY="$proxy_url"
    export NO_PROXY="localhost,127.0.0.1"

    # Configure git to ignore proxy
    configure_git_no_proxy

    # Save credentials
    save_credentials "$proxy_url"
}

#######################################
# Save current git proxy settings
#######################################
save_git_proxy_settings() {
    # Create backup file with restricted permissions
    touch "$GIT_BACKUP_FILE"
    chmod 600 "$GIT_BACKUP_FILE"

    # Get current git proxy settings (global config)
    local http_proxy=$(git config --global --get http.proxy 2>/dev/null || echo "")
    local https_proxy=$(git config --global --get https.proxy 2>/dev/null || echo "")

    # Save to backup file
    cat > "$GIT_BACKUP_FILE" << EOF
HTTP_PROXY=$http_proxy
HTTPS_PROXY=$https_proxy
EOF
}

#######################################
# Configure git to ignore proxy
#######################################
configure_git_no_proxy() {
    # Save current settings before modifying
    save_git_proxy_settings

    # Disable proxy for git by setting empty values
    git config --global http.proxy "" 2>/dev/null || true
    git config --global https.proxy "" 2>/dev/null || true

    print_info "Git configured to bypass proxy"
}

#######################################
# Restore git proxy settings from backup
#######################################
restore_git_proxy() {
    if [[ ! -f "$GIT_BACKUP_FILE" ]]; then
        print_info "No git proxy backup found"
        return 0
    fi

    # Load backup settings
    source "$GIT_BACKUP_FILE"

    # Restore settings
    if [[ -n "$HTTP_PROXY" ]]; then
        git config --global http.proxy "$HTTP_PROXY"
    else
        git config --global --unset http.proxy 2>/dev/null || true
    fi

    if [[ -n "$HTTPS_PROXY" ]]; then
        git config --global https.proxy "$HTTPS_PROXY"
    else
        git config --global --unset https.proxy 2>/dev/null || true
    fi

    print_success "Git proxy settings restored"

    # Remove backup file
    rm -f "$GIT_BACKUP_FILE"
}

#######################################
# Display proxy info
#######################################
display_proxy_info() {
    local show_password=${1:-false}

    echo ""
    print_success "Proxy configured:"
    echo ""

    if [[ "$show_password" == "true" ]]; then
        echo "  HTTPS_PROXY: $HTTPS_PROXY"
        echo "  HTTP_PROXY:  $HTTP_PROXY"
    else
        # Hide password
        local masked_https=$(echo "$HTTPS_PROXY" | sed -E 's|://([^:]+):([^@]+)@|://\1:****@|')
        local masked_http=$(echo "$HTTP_PROXY" | sed -E 's|://([^:]+):([^@]+)@|://\1:****@|')
        echo "  HTTPS_PROXY: $masked_https"
        echo "  HTTP_PROXY:  $masked_http"
    fi

    echo "  NO_PROXY:    $NO_PROXY"
    echo ""

    # Show git proxy status
    local git_http_proxy=$(git config --global --get http.proxy 2>/dev/null || echo "(none)")
    local git_https_proxy=$(git config --global --get https.proxy 2>/dev/null || echo "(none)")

    print_info "Git proxy settings (bypassed for push/pull):"
    echo "  http.proxy:  $git_http_proxy"
    echo "  https.proxy: $git_https_proxy"
    echo ""
}

#######################################
# Test proxy connectivity
#######################################
test_proxy() {
    print_info "Testing proxy connectivity..."

    if curl -s -m 5 -o /dev/null -w "%{http_code}" https://www.google.com | grep -q "200"; then
        print_success "Proxy connection successful"
        return 0
    else
        print_warning "Proxy test failed (but Claude Code may still work)"
        return 1
    fi
}

#######################################
# Clear saved credentials
#######################################
clear_credentials() {
    if [[ -f "$CREDENTIALS_FILE" ]]; then
        rm -f "$CREDENTIALS_FILE"
        print_success "Saved credentials cleared"
    else
        print_info "No saved credentials found"
    fi
}

#######################################
# Install Node.js and npm
#######################################
install_nodejs() {
    print_info "Installing Node.js and npm..."
    echo ""

    # Use NodeSource setup script for latest LTS
    if curl -fsSL https://deb.nodesource.com/setup_18.x | bash -; then
        if apt-get install -y nodejs; then
            print_success "Node.js and npm installed successfully"
            echo ""
            node --version
            npm --version
            echo ""
            return 0
        else
            print_error "Failed to install Node.js package"
            return 1
        fi
    else
        print_error "Failed to download Node.js setup script"
        return 1
    fi
}

#######################################
# Install Claude Code globally
#######################################
install_claude_code() {
    local using_nvm=false

    # Detect NVM environment
    if detect_nvm; then
        using_nvm=true
        print_info "Detected NVM environment"
        echo ""
    fi

    if [[ "$using_nvm" == true ]]; then
        print_info "Installing Claude Code to NVM environment..."
    else
        print_info "Installing Claude Code globally..."
    fi
    echo ""

    if npm install -g @anthropic-ai/claude-code; then
        print_success "Claude Code installed successfully"
        echo ""
        if [[ "$using_nvm" == true ]]; then
            print_info "Installed to: $(npm prefix -g)/bin/claude"
        fi
        claude --version 2>/dev/null || print_warning "Claude version check failed (may need to restart shell)"
        echo ""
        return 0
    else
        print_error "Failed to install Claude Code"
        return 1
    fi
}

#######################################
# Get Claude Code version
#######################################
get_claude_version() {
    local claude_cmd=""

    # Priority 1: Check NVM environment first
    if detect_nvm; then
        local nvm_claude=$(get_nvm_claude_path)
        if [[ -n "$nvm_claude" ]]; then
            claude_cmd="$nvm_claude"
        fi
    fi

    # Priority 2: Check system locations if NVM not found
    if [[ -z "$claude_cmd" ]]; then
        if command -v claude &> /dev/null; then
            local cmd_path=$(command -v claude)
            # Skip if it's from NVM (already checked)
            if [[ "$cmd_path" != *".nvm"* ]]; then
                claude_cmd="claude"
            fi
        elif [[ -x "/usr/local/bin/claude" ]]; then
            claude_cmd="/usr/local/bin/claude"
        elif [[ -x "/usr/bin/claude" ]]; then
            claude_cmd="/usr/bin/claude"
        else
            local global_npm_prefix=$(npm prefix -g 2>/dev/null)
            if [[ -n "$global_npm_prefix" ]] && [[ -x "$global_npm_prefix/bin/claude" ]]; then
                claude_cmd="$global_npm_prefix/bin/claude"
            fi
        fi
    fi

    if [[ -z "$claude_cmd" ]]; then
        echo "not installed"
        return 1
    fi

    # Get version
    local version=$($claude_cmd --version 2>/dev/null | head -n 1)
    if [[ -z "$version" ]]; then
        echo "unknown"
        return 1
    fi

    echo "$version"
    return 0
}

#######################################
# Check for available updates
#######################################
check_update() {
    print_info "Checking for Claude Code updates..."
    echo ""

    # Detect NVM environment
    local using_nvm=false
    if detect_nvm; then
        using_nvm=true
    fi

    # Get current version
    local current_version=$(get_claude_version)
    if [[ "$current_version" == "not installed" ]]; then
        print_error "Claude Code is not installed"
        echo ""
        if [[ "$using_nvm" == true ]]; then
            echo "Install with: npm install -g @anthropic-ai/claude-code"
        else
            echo "Install with: sudo init_claude --install"
        fi
        return 1
    fi

    print_info "Current version: $current_version"
    echo ""

    # Get latest version from npm
    print_info "Fetching latest version from npm..."
    local latest_version=$(npm view @anthropic-ai/claude-code version 2>/dev/null)

    if [[ -z "$latest_version" ]]; then
        print_error "Failed to fetch latest version from npm"
        return 1
    fi

    print_info "Latest version:  $latest_version"
    echo ""

    # Compare versions
    if [[ "$current_version" == *"$latest_version"* ]]; then
        print_success "You are running the latest version"
    else
        print_warning "An update is available: $latest_version"
        echo ""
        if [[ "$using_nvm" == true ]]; then
            echo "Run to update: init_claude --update"
            echo "Or directly:   npm install -g @anthropic-ai/claude-code@latest"
        else
            echo "Run to update: sudo init_claude --update"
        fi
    fi

    return 0
}

#######################################
# Cleanup old Claude Code installations (NVM only)
#######################################
cleanup_old_claude_installations() {
	if [[ -z "${NVM_DIR:-}" ]]; then
		return 0  # Only for NVM installations
	fi

	local npm_prefix=$(npm prefix -g 2>/dev/null)
	if [[ -z "$npm_prefix" ]] || [[ "$npm_prefix" != *".nvm"* ]]; then
		return 0  # Not NVM environment
	fi

	local lib_dir="$npm_prefix/lib/node_modules/@anthropic-ai"
	local bin_dir="$npm_prefix/bin"

	if [[ ! -d "$lib_dir" ]]; then
		return 0  # No installations to clean
	fi

	local cleaned=false

	# Find temporary .claude-code-* folders
	local temp_folders=$(find "$lib_dir" -maxdepth 1 -type d -name ".claude-code-*" 2>/dev/null)

	if [[ -n "$temp_folders" ]]; then
		print_info "Found old temporary Claude installations:"
		echo "$temp_folders" | while read folder; do
			echo "  - $(basename "$folder")"
		done
		echo ""

		read -p "Remove old temporary installations? (Y/n): " confirm
		if [[ -z "$confirm" ]] || [[ "$confirm" =~ ^[Yy]$ ]]; then
			echo "$temp_folders" | while read folder; do
				if rm -rf "$folder" 2>/dev/null; then
					print_success "Removed: $(basename "$folder")"
					cleaned=true
				else
					print_warning "Failed to remove: $(basename "$folder")"
				fi
			done
			echo ""
		fi
	fi

	# Find and remove broken symlinks in bin/
	if [[ -d "$bin_dir" ]]; then
		local broken_links=$(find "$bin_dir" -type l -name ".claude-*" ! -exec test -e {} \; -print 2>/dev/null)

		if [[ -n "$broken_links" ]]; then
			print_info "Found broken Claude symlinks:"
			echo "$broken_links" | while read link; do
				echo "  - $(basename "$link")"
			done
			echo ""

			read -p "Remove broken symlinks? (Y/n): " confirm
			if [[ -z "$confirm" ]] || [[ "$confirm" =~ ^[Yy]$ ]]; then
				echo "$broken_links" | while read link; do
					if rm -f "$link" 2>/dev/null; then
						print_success "Removed: $(basename "$link")"
						cleaned=true
					fi
				done
				echo ""
			fi
		fi
	fi

	# Check for incomplete claude-code installation (without cli.js)
	if [[ -d "$lib_dir/claude-code" ]] && [[ ! -f "$lib_dir/claude-code/cli.js" ]]; then
		print_warning "Found incomplete installation: claude-code (no cli.js)"
		echo ""

		read -p "Remove incomplete installation? (Y/n): " confirm
		if [[ -z "$confirm" ]] || [[ "$confirm" =~ ^[Yy]$ ]]; then
			if rm -rf "$lib_dir/claude-code" 2>/dev/null; then
				print_success "Removed incomplete installation"
				cleaned=true
				echo ""
			fi
		fi
	fi

	if [[ "$cleaned" == true ]]; then
		print_success "Cleanup completed"
		echo ""
	fi

	return 0
}

#######################################
# Update Claude Code
#######################################
update_claude_code() {
    local using_nvm=false

    # Detect NVM environment
    if detect_nvm; then
        using_nvm=true
        print_info "Detected NVM environment"
        echo ""
    fi

    # Check if running with sudo (only required for system installations)
    if [[ "$using_nvm" == false ]] && [[ $EUID -ne 0 ]]; then
        print_error "Update requires sudo privileges for system installation"
        echo ""
        echo "Run: sudo $0 --update"
        exit 1
    fi

    # Warn if using sudo with NVM
    if [[ "$using_nvm" == true ]] && [[ $EUID -eq 0 ]]; then
        print_warning "Running with sudo, but NVM installation detected"
        print_warning "This will update the system installation, not NVM"
        echo ""
        read -p "Continue with system update? (y/N): " confirm_sudo
        if [[ ! "$confirm_sudo" =~ ^[Yy]$ ]]; then
            print_info "Update cancelled"
            echo ""
            echo "Run without sudo to update NVM installation:"
            echo "  init_claude --update"
            exit 0
        fi
        using_nvm=false  # Treat as system installation
    fi

    print_info "Updating Claude Code..."
    echo ""

    # Get current version
    local current_version=$(get_claude_version)
    if [[ "$current_version" == "not installed" ]]; then
        print_error "Claude Code is not installed"
        echo ""
        if [[ "$using_nvm" == true ]]; then
            echo "Install first with: npm install -g @anthropic-ai/claude-code"
        else
            echo "Install first with: sudo init_claude --install"
        fi
        exit 1
    fi

    print_info "Current version: $current_version"
    echo ""

    # Get latest version
    local latest_version=$(npm view @anthropic-ai/claude-code version 2>/dev/null)
    if [[ -n "$latest_version" ]]; then
        print_info "Latest version:  $latest_version"
        echo ""
    fi

    # Check if already up to date
    if [[ "$current_version" == *"$latest_version"* ]]; then
        print_success "Already running the latest version"
        return 0
    fi

    # Confirm update
    read -p "Proceed with update? (Y/n): " confirm_update
    if [[ -n "$confirm_update" ]] && [[ ! "$confirm_update" =~ ^[Yy]$ ]]; then
        print_info "Update cancelled"
        return 0
    fi

    echo ""

    # Cleanup old installations if using NVM
    if [[ "$using_nvm" == true ]]; then
        cleanup_old_claude_installations
    fi

    if [[ "$using_nvm" == true ]]; then
        print_info "Installing update to NVM environment..."
    else
        print_info "Installing update to system..."
    fi
    echo ""

    # Update via npm (use install instead of update for npm 10+ compatibility)
    if npm install -g @anthropic-ai/claude-code@latest; then
        echo ""

        # Verify installation success by checking for cli.js
        local claude_path=$(get_nvm_claude_path 2>/dev/null)
        if [[ -z "$claude_path" ]] || [[ "$claude_path" == *"not found"* ]]; then
            print_error "Update installed but Claude Code not found"
            echo ""
            echo "The npm install succeeded but Claude Code is not accessible."
            echo "This might be due to temporary installation files."
            echo ""
            echo "Try running cleanup again:"
            echo "  init_claude --update"
            echo ""
            echo "Or manually:"
            echo "  npm uninstall -g @anthropic-ai/claude-code"
            echo "  npm install -g @anthropic-ai/claude-code@latest"
            return 1
        fi

        print_success "Claude Code updated successfully"
        echo ""

        # Clear bash command hash cache to ensure new version is used
        hash -r 2>/dev/null || true

        # Show new version
        local new_version=$(get_claude_version)
        if [[ "$new_version" != "not installed" ]] && [[ "$new_version" != "unknown" ]]; then
            print_info "New version: $new_version"

            # Check if version actually updated
            if [[ "$new_version" != *"$latest_version"* ]]; then
                print_warning "Version still shows: $new_version"
                echo ""
                echo "The update was installed but your shell may be using a cached version."
                echo "Please restart your terminal or run: hash -r"
            fi
        fi

        return 0
    else
        echo ""
        print_error "Failed to update Claude Code"
        echo ""

        # Suggest cleanup if it's an NVM installation
        if [[ "$using_nvm" == true ]]; then
            echo "If you see ENOTEMPTY errors, try:"
            echo "  1. Run: init_claude --update (cleanup will run automatically)"
            echo "  2. Or manually remove old installations:"
            echo "     rm -rf ~/.nvm/versions/node/*/lib/node_modules/@anthropic-ai/.claude-code-*"
            echo ""
        fi

        echo "Or try manually:"
        echo "  npm install -g @anthropic-ai/claude-code@latest"
        return 1
    fi
}

#######################################
# Check and install dependencies
#######################################
check_dependencies() {
    local needs_install=false

    echo ""
    print_info "Checking dependencies..."
    echo ""

    # Check npm
    if ! command -v npm &> /dev/null; then
        print_warning "npm not found"
        needs_install=true

        read -p "Install Node.js and npm? (Y/n): " install_node
        if [[ -z "$install_node" ]] || [[ "$install_node" =~ ^[Yy]$ ]]; then
            if ! install_nodejs; then
                print_error "Cannot proceed without npm"
                exit 1
            fi
        else
            print_error "npm is required to run Claude Code"
            echo ""
            echo "Install manually:"
            echo "  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
            echo "  sudo apt-get install -y nodejs"
            exit 1
        fi
    else
        print_success "npm found: $(npm --version)"

        # Detect and show NVM info
        if detect_nvm; then
            local npm_prefix=$(npm prefix -g 2>/dev/null)
            print_info "NVM environment detected"
            if [[ -n "$npm_prefix" ]]; then
                print_info "Global packages location: $npm_prefix"
            fi
        fi
    fi

    # Check Claude Code (check multiple locations, prioritize NVM)
    local claude_found=false

    # Check NVM first
    if detect_nvm; then
        local nvm_claude=$(get_nvm_claude_path)
        if [[ -n "$nvm_claude" ]]; then
            claude_found=true
        fi
    fi

    # Check system locations if not found in NVM
    if [[ "$claude_found" == false ]]; then
        if command -v claude &> /dev/null; then
            local cmd_path=$(command -v claude)
            # Don't count NVM paths here (already checked)
            if [[ "$cmd_path" != *".nvm"* ]]; then
                claude_found=true
            fi
        elif [[ -x "/usr/local/bin/claude" || -x "/usr/bin/claude" ]]; then
            claude_found=true
        else
            # Check npm global prefix (non-NVM)
            local global_npm_prefix=$(npm prefix -g 2>/dev/null)
            if [[ -n "$global_npm_prefix" ]] && [[ "$global_npm_prefix" != *".nvm"* ]]; then
                if [[ -x "$global_npm_prefix/bin/claude" ]] || ls "$global_npm_prefix/bin/.claude-"* &>/dev/null; then
                    claude_found=true
                fi
            fi
        fi
    fi

    if [[ "$claude_found" == false ]]; then
        print_warning "Claude Code not found"
        needs_install=true

        echo ""
        read -p "Install Claude Code globally? (Y/n): " install_claude
        if [[ -z "$install_claude" ]] || [[ "$install_claude" =~ ^[Yy]$ ]]; then
            if ! install_claude_code; then
                print_error "Cannot proceed without Claude Code"
                exit 1
            fi
        else
            print_warning "Claude Code is not installed"
            echo ""
            echo "Install manually:"
            echo "  npm install -g @anthropic-ai/claude-code"
            echo ""
            echo "You can still install init_claude, but it won't work until Claude Code is installed."
            read -p "Continue anyway? (y/N): " continue_anyway
            if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        print_success "Claude Code found"
    fi

    echo ""
}

#######################################
# Install script globally
#######################################
install_script() {
    local script_path="${BASH_SOURCE[0]}"
    local target_path="/usr/local/bin/init_claude"

    # Check if running with sudo
    if [[ $EUID -ne 0 ]]; then
        print_error "Installation requires sudo privileges"
        echo ""
        echo "Run: sudo $0 --install"
        exit 1
    fi

    # Check and install dependencies
    check_dependencies

    # Check if already installed
    if [[ -L "$target_path" ]]; then
        local current_target=$(readlink -f "$target_path")
        local script_realpath=$(readlink -f "$script_path")

        if [[ "$current_target" == "$script_realpath" ]]; then
            print_info "Already installed at: $target_path"
            return 0
        else
            print_warning "Different version found at: $target_path"
            echo "  Current: $current_target"
            echo "  New:     $script_realpath"
            echo ""
            read -p "Replace existing installation? (y/N): " replace

            if [[ ! "$replace" =~ ^[Yy]$ ]]; then
                print_info "Installation cancelled"
                return 1
            fi
        fi
    fi

    # Create symlink
    ln -sf "$(readlink -f "$script_path")" "$target_path"
    chmod +x "$target_path"

    print_success "Installed to: $target_path"
    echo ""
    echo "You can now run: init_claude"
}

#######################################
# Uninstall script
#######################################
uninstall_script() {
    local target_path="/usr/local/bin/init_claude"

    # Check if running with sudo
    if [[ $EUID -ne 0 ]]; then
        print_error "Uninstallation requires sudo privileges"
        echo ""
        echo "Run: sudo $0 --uninstall"
        exit 1
    fi

    # Check if installed
    if [[ ! -e "$target_path" ]]; then
        print_info "Not installed (no file at $target_path)"
        return 0
    fi

    # Remove symlink
    rm -f "$target_path"
    print_success "Uninstalled from: $target_path"
}

#######################################
# Launch Claude Code
#######################################
launch_claude() {
    echo ""
    print_info "Launching Claude Code..."
    echo ""

    # Find claude installation
    local claude_cmd=""

    # Priority 1: Check NVM environment first (user's active version)
    if detect_nvm; then
        local nvm_claude=$(get_nvm_claude_path)
        if [[ -n "$nvm_claude" ]]; then
            claude_cmd="$nvm_claude"
            print_info "Using NVM installation"
        fi
    fi

    # Priority 2: Check system global locations if NVM not found
    if [[ -z "$claude_cmd" ]]; then
        if [[ -x "/usr/local/bin/claude" ]]; then
            claude_cmd="/usr/local/bin/claude"
        elif [[ -x "/usr/bin/claude" ]]; then
            claude_cmd="/usr/bin/claude"
        elif command -v claude &> /dev/null; then
            # Fall back to whatever is in PATH, but warn if it's local
            claude_cmd=$(command -v claude)
            local claude_dir=$(dirname "$claude_cmd")
            # Skip if it's from NVM (already checked) or local installation
            if [[ "$claude_cmd" == *".nvm"* ]]; then
                # Already checked in NVM, shouldn't happen but just in case
                :
            elif [[ "$claude_dir" == "." || "$claude_dir" == "$PWD" || "$claude_dir" == "./node_modules/.bin" ]]; then
                print_warning "Found local Claude installation: $claude_cmd"
                print_info "Looking for global installation..."
                claude_cmd=""
            fi
        fi
    fi

    # Priority 3: Try npm global prefix
    if [[ -z "$claude_cmd" ]]; then
        local global_npm_prefix=$(npm prefix -g 2>/dev/null)
        if [[ -n "$global_npm_prefix" ]] && [[ "$global_npm_prefix" != *".nvm"* ]]; then
            # Check for claude in npm global bin
            if [[ -x "$global_npm_prefix/bin/claude" ]]; then
                claude_cmd="$global_npm_prefix/bin/claude"
            # Check for .claude-* temporary files
            elif ls "$global_npm_prefix/bin/.claude-"* &>/dev/null; then
                local temp_claude=$(ls "$global_npm_prefix/bin/.claude-"* 2>/dev/null | head -n 1)
                if [[ -x "$temp_claude" ]]; then
                    claude_cmd="$temp_claude"
                    print_warning "Using temporary Claude binary: $(basename "$temp_claude")"
                fi
            fi
        fi
    fi

    # If still not found, try npx as fallback
    if [[ -z "$claude_cmd" ]]; then
        if command -v npx &> /dev/null; then
            print_info "Using npx to run Claude Code..."
            exec npx @anthropic-ai/claude-code "$@"
        else
            print_error "Claude Code not found"
            echo ""
            echo "Install Claude Code globally:"
            echo "  npm install -g @anthropic-ai/claude-code"
            exit 1
        fi
    fi

    print_info "Using Claude Code: $claude_cmd"
    echo ""

    # Pass through any additional arguments
    # Use eval if command contains spaces (e.g., "node /path/to/cli.js")
    if [[ "$claude_cmd" == *" "* ]]; then
        eval exec "$claude_cmd" '"$@"'
    else
        exec "$claude_cmd" "$@"
    fi
}

#######################################
# Show usage
#######################################
show_usage() {
    cat << EOF
Usage: init_claude [OPTIONS] [CLAUDE_ARGS...]

Initialize Claude Code with HTTP proxy settings

OPTIONS:
  -h, --help                        Show this help message
  -p, --proxy URL                   Set proxy URL directly (skip prompt)
  -t, --test                        Test proxy and exit (don't launch Claude)
  -c, --clear                       Clear saved credentials
  --no-proxy                        Launch Claude Code without proxy
  --restore-git-proxy               Restore git proxy settings from backup
  --install                         Install script globally (requires sudo)
  --uninstall                       Uninstall script from system (requires sudo)
  --update                          Update Claude Code to latest version (requires sudo)
  --check-update                    Check for available updates without installing
  --no-test                         Skip proxy connectivity test
  --show-password                   Display password in output (default: masked)
  --dangerously-skip-permissions    Pass --dangerously-skip-permissions to Claude Code

EXAMPLES:
  # Install globally (run once)
  sudo $0 --install

  # First run - prompt for proxy URL
  init_claude

  # Second run - use saved credentials automatically
  init_claude

  # Set proxy URL directly
  init_claude --proxy http://user:pass@127.0.0.1:8118

  # Test proxy without launching Claude
  init_claude --test

  # Clear saved credentials
  init_claude --clear

  # Restore git proxy settings from backup
  init_claude --restore-git-proxy

  # Launch without proxy
  init_claude --no-proxy

  # Uninstall
  sudo init_claude --uninstall

  # Check for updates
  init_claude --check-update

  # Update Claude Code to latest version
  sudo init_claude --update

  # Pass arguments to Claude Code
  init_claude -- --model claude-3-opus

  # Skip permission checks (use with caution)
  init_claude --dangerously-skip-permissions

PROXY URL FORMAT:
  http://username:password@host:port
  https://username:password@host:port
  socks5://username:password@host:port

  Examples:
    http://alice:secret123@127.0.0.1:8118
    socks5://bob:pass456@proxy.example.com:1080

CREDENTIALS:
  - Saved to: ${CREDENTIALS_FILE}
  - File permissions: 600 (owner read/write only)
  - Automatically excluded from git (.gitignore)
  - Reused on subsequent runs (prompt to confirm/change)

ENVIRONMENT:
  After loading proxy, these variables are set:
    HTTPS_PROXY, HTTP_PROXY, NO_PROXY

GIT PROXY:
  When proxy is configured, git is automatically set to bypass proxy.
  This prevents issues with git push/pull through HTTP proxies.

  Your original git proxy settings are backed up to:
    ${GIT_BACKUP_FILE}

  To restore original git proxy settings:
    init_claude --restore-git-proxy

INSTALLATION:
  After installing with --install, you can run 'init_claude' from anywhere.
  The script will be available at: /usr/local/bin/init_claude

EOF
}

#######################################
# Main
#######################################
main() {
    local test_mode=false
    local skip_test=false
    local show_password=false
    local proxy_url=""
    local skip_permissions=false
    local no_proxy=false
    local claude_args=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -p|--proxy)
                proxy_url="$2"
                shift 2
                ;;
            -t|--test)
                test_mode=true
                shift
                ;;
            -c|--clear)
                clear_credentials
                exit 0
                ;;
            --restore-git-proxy)
                restore_git_proxy
                exit 0
                ;;
            --no-proxy)
                no_proxy=true
                shift
                ;;
            --install)
                install_script
                exit $?
                ;;
            --uninstall)
                uninstall_script
                exit $?
                ;;
            --update)
                update_claude_code
                exit $?
                ;;
            --check-update)
                check_update
                exit $?
                ;;
            --no-test)
                skip_test=true
                shift
                ;;
            --show-password)
                show_password=true
                shift
                ;;
            --dangerously-skip-permissions)
                skip_permissions=true
                shift
                ;;
            --)
                shift
                claude_args=("$@")
                break
                ;;
            *)
                claude_args+=("$1")
                shift
                ;;
        esac
    done

    echo ""
    echo "═══════════════════════════════════════"
    echo "  Claude Code Proxy Initializer v2.0"
    echo "═══════════════════════════════════════"
    echo ""

    # Check if --no-proxy flag is set
    if [[ "$no_proxy" == true ]]; then
        print_info "Running without proxy"
        echo ""

        # Ensure proxy variables are unset
        unset HTTPS_PROXY
        unset HTTP_PROXY
        unset NO_PROXY

        # Restore git proxy settings if backup exists
        if [[ -f "$GIT_BACKUP_FILE" ]]; then
            restore_git_proxy
        fi

        # Add --dangerously-skip-permissions flag if requested
        if [[ "$skip_permissions" == true ]]; then
            claude_args+=("--dangerously-skip-permissions")
            print_warning "Skipping permission checks (--dangerously-skip-permissions)"
            echo ""
        fi

        # Launch Claude Code without proxy
        launch_claude "${claude_args[@]}"
        exit 0
    fi

    # Get proxy URL (from argument, saved file, or prompt)
    if [[ -z "$proxy_url" ]]; then
        proxy_url=$(prompt_proxy_url)
    else
        # Validate provided URL
        if ! validate_proxy_url "$proxy_url"; then
            print_error "Invalid proxy URL: $proxy_url"
            echo "Expected format: protocol://[user:pass@]host:port"
            exit 1
        fi
    fi

    # Configure proxy
    print_info "Configuring proxy..."
    configure_proxy_from_url "$proxy_url"

    # Display configuration
    display_proxy_info "$show_password"

    # Test proxy (unless skipped)
    if [[ "$skip_test" == false ]]; then
        test_proxy
        echo ""
    fi

    # If test mode, exit here
    if [[ "$test_mode" == true ]]; then
        print_success "Test complete"
        exit 0
    fi

    # Add --dangerously-skip-permissions flag if requested
    if [[ "$skip_permissions" == true ]]; then
        claude_args+=("--dangerously-skip-permissions")
        print_warning "Skipping permission checks (--dangerously-skip-permissions)"
        echo ""
    fi

    # Launch Claude Code
    launch_claude "${claude_args[@]}"
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

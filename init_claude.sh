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

    # Save credentials
    save_credentials "$proxy_url"
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
    print_info "Installing Claude Code globally..."
    echo ""

    if npm install -g @anthropic-ai/claude-code; then
        print_success "Claude Code installed successfully"
        echo ""
        claude --version 2>/dev/null || print_warning "Claude version check failed (may need to restart shell)"
        echo ""
        return 0
    else
        print_error "Failed to install Claude Code"
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
    fi

    # Check Claude Code
    if ! command -v claude &> /dev/null && ! [[ -x "/usr/local/bin/claude" || -x "/usr/bin/claude" ]]; then
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

    # Find global claude installation
    local claude_cmd=""
    
    # Check common global locations in priority order
    if [[ -x "/usr/local/bin/claude" ]]; then
        claude_cmd="/usr/local/bin/claude"
    elif [[ -x "/usr/bin/claude" ]]; then
        claude_cmd="/usr/bin/claude"
    elif command -v claude &> /dev/null; then
        # Fall back to whatever is in PATH, but warn if it's local
        claude_cmd=$(command -v claude)
        local claude_dir=$(dirname "$claude_cmd")
        if [[ "$claude_dir" == "." || "$claude_dir" == "$PWD" || "$claude_dir" == "$(npm bin)" || "$claude_dir" == "./node_modules/.bin" ]]; then
            print_warning "Found local Claude installation: $claude_cmd"
            print_info "Looking for global installation..."
            
            # Try to find global npm installation
            local global_npm_bin=$(npm bin -g 2>/dev/null)
            if [[ -n "$global_npm_bin" && -x "$global_npm_bin/claude" ]]; then
                claude_cmd="$global_npm_bin/claude"
                print_success "Using global installation: $claude_cmd"
            else
                print_error "Global Claude Code installation not found"
                echo ""
                echo "Install Claude Code globally:"
                echo "  npm install -g @anthropic-ai/claude-code"
                exit 1
            fi
        fi
    else
        print_error "Claude Code not found"
        echo ""
        echo "Install Claude Code globally:"
        echo "  npm install -g @anthropic-ai/claude-code"
        exit 1
    fi

    print_info "Using Claude Code: $claude_cmd"
    
    # Pass through any additional arguments
    exec "$claude_cmd" "$@"
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
  --install                         Install script globally (requires sudo)
  --uninstall                       Uninstall script from system (requires sudo)
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

  # Launch without proxy
  init_claude --no-proxy

  # Uninstall
  sudo init_claude --uninstall

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

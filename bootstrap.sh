#!/usr/bin/env zsh

# macOS Development Environment Setup - Bootstrap Script
# One-command installer: curl -fsSL https://raw.githubusercontent.com/26zl/MacOS-Dev-Setup/main/bootstrap.sh | zsh
#
# This script clones the repository and runs the installation.
# After installation, the cloned repo can be safely removed.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/26zl/MacOS-Dev-Setup.git"
CLONE_DIR="${TMPDIR:-/tmp}/MacOS-Dev-Setup-$$"

echo "${GREEN}🚀 macOS Development Environment Setup${NC}"
echo "========================================"
echo ""

# Check macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "${RED}ERROR: This script is designed for macOS only${NC}"
  exit 1
fi

# Check for git (comes with Xcode CLT, but may not be installed yet)
if ! command -v git >/dev/null 2>&1; then
  echo "${YELLOW}Git not found. Installing Xcode Command Line Tools...${NC}"
  echo "${BLUE}INFO:${NC} A dialog will appear - please click 'Install' and wait for completion"
  xcode-select --install 2>/dev/null || true
  echo ""
  echo "${YELLOW}After Xcode CLT installation completes, re-run this command:${NC}"
  echo "  curl -fsSL https://raw.githubusercontent.com/26zl/MacOS-Dev-Setup/main/bootstrap.sh | zsh"
  exit 0
fi

# Cleanup on exit
cleanup() {
  rm -rf "$CLONE_DIR" 2>/dev/null || true
}
trap cleanup EXIT INT TERM HUP

# Clone repository
echo "Downloading setup files..."
if git clone --depth=1 "$REPO_URL" "$CLONE_DIR" 2>/dev/null; then
  echo "${GREEN}✅ Downloaded${NC}"
else
  echo "${RED}ERROR: Failed to download. Check your network connection.${NC}"
  exit 1
fi

echo ""

# Run install.sh
cd "$CLONE_DIR"
chmod +x install.sh
./install.sh

# Offer dev-tools
echo ""
echo "${BLUE}INFO:${NC} Core setup complete."
echo ""
echo "Optional: Install development language tools (Python, Node.js, Rust, Go, etc.)?"
echo -n "[y/N]: "
read -r response
case "$response" in
  [Yy]|[Yy][Ee][Ss])
    chmod +x dev-tools.sh
    ./dev-tools.sh
    ;;
  *)
    echo "${BLUE}INFO:${NC} Skipped. You can run dev-tools.sh later from the repo."
    ;;
esac

echo ""
echo "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "Run: source ~/.zshrc"
echo ""

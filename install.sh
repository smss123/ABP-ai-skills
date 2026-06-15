#!/usr/bin/env bash
# install.sh — ABP AI Skills installer
# Usage:
#   ./install.sh /path/to/your-abp-project
#   ./install.sh /path/to/your-abp-project --platform claude
#
# One-liner (no clone needed):
#   curl -sSL https://raw.githubusercontent.com/smss123/ABP-ai-skills/main/install.sh | bash -s -- /path/to/your-abp-project

set -euo pipefail

REPO_URL="https://github.com/smss123/ABP-ai-skills.git"
REPO_BRANCH="main"

# ── colours ──────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  CYAN='\033[0;36m';  RED='\033[0;31m'; RESET='\033[0m'
else
  GREEN=''; YELLOW=''; CYAN=''; RED=''; RESET=''
fi

banner() {
  echo -e "${CYAN}"
  echo "╔══════════════════════════════════════════════════╗"
  echo "║         ABP AI Skills — Auto Installer           ║"
  echo "║  GitHub Copilot · Claude Code · Windsurf         ║"
  echo "║  Continue.dev  · any AI assistant                ║"
  echo "╚══════════════════════════════════════════════════╝"
  echo -e "${RESET}"
}

usage() {
  echo "Usage: $0 [TARGET_DIR] [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --platform <all|copilot|claude|windsurf|continue>  (default: all)"
  echo "  --overwrite     Overwrite existing files without prompting"
  echo "  --help          Show this help"
  echo ""
  echo "Examples:"
  echo "  $0 /path/to/my-abp-project"
  echo "  $0 /path/to/my-abp-project --platform claude"
  echo "  $0 /path/to/my-abp-project --platform copilot --overwrite"
  echo ""
  echo "Remote (no clone needed):"
  echo "  curl -sSL https://raw.githubusercontent.com/smss123/ABP-ai-skills/main/install.sh \\"
  echo "    | bash -s -- /path/to/my-abp-project"
}

# ── argument parsing ─────────────────────────────────────────────────────────
TARGET_DIR=""
PLATFORM="all"
OVERWRITE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)   PLATFORM="${2:-all}"; shift 2 ;;
    --overwrite)  OVERWRITE=true; shift ;;
    --help|-h)    usage; exit 0 ;;
    -*)           echo -e "${RED}Unknown option: $1${RESET}"; usage; exit 1 ;;
    *)            TARGET_DIR="$1"; shift ;;
  esac
done

# Validate platform
case "$PLATFORM" in
  all|copilot|claude|windsurf|continue) ;;
  *) echo -e "${RED}Invalid platform '$PLATFORM'. Choose: all copilot claude windsurf continue${RESET}"; exit 1 ;;
esac

# Prompt for target if not provided and stdin is a terminal
if [[ -z "$TARGET_DIR" ]]; then
  if [[ -t 0 ]]; then
    read -rp "Enter path to your ABP project directory: " TARGET_DIR
  else
    echo -e "${RED}Error: TARGET_DIR is required when piping from curl.${RESET}"
    echo "  curl ... | bash -s -- /path/to/project"
    exit 1
  fi
fi

TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
TARGET_DIR="$(realpath -m "$TARGET_DIR" 2>/dev/null || echo "$TARGET_DIR")"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo -e "${RED}Error: Directory '$TARGET_DIR' does not exist.${RESET}"
  exit 1
fi

# ── locate source ─────────────────────────────────────────────────────────────
SRC_DIR=""
TEMP_DIR=""

# Running from within the cloned repo?
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
if [[ -f "$SCRIPT_DIR/CLAUDE.md" && -d "$SCRIPT_DIR/abp-dev/references" ]]; then
  SRC_DIR="$SCRIPT_DIR"
  echo -e "${GREEN}✓ Using local repo: $SRC_DIR${RESET}"
else
  # Download via git clone
  if ! command -v git &>/dev/null; then
    echo -e "${RED}Error: 'git' is required. Install git and try again.${RESET}"
    exit 1
  fi
  TEMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TEMP_DIR"' EXIT
  echo -e "${CYAN}⬇  Downloading ABP AI Skills...${RESET}"
  git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$TEMP_DIR" --quiet
  SRC_DIR="$TEMP_DIR"
  echo -e "${GREEN}✓ Downloaded${RESET}"
fi

# ── copy helper ───────────────────────────────────────────────────────────────
copy_item() {
  local src="$1"
  local dest_parent="$2"
  local name
  name="$(basename "$src")"
  local dest="$dest_parent/$name"

  if [[ -e "$dest" ]] && [[ "$OVERWRITE" == false ]]; then
    if [[ -t 0 ]]; then
      read -rp "  '$name' already exists in target. Overwrite? [y/N] " confirm
      [[ "$confirm" =~ ^[Yy]$ ]] || { echo -e "  ${YELLOW}↷ skipped${RESET} $name"; return 0; }
    else
      echo -e "  ${YELLOW}↷ skipped${RESET} $name (use --overwrite to replace)"
      return 0
    fi
  fi

  cp -r "$src" "$dest_parent/"
  echo -e "  ${GREEN}✓${RESET} $name"
}

# ── install ───────────────────────────────────────────────────────────────────
banner
echo -e "Target : ${YELLOW}$TARGET_DIR${RESET}"
echo -e "Platform: ${YELLOW}$PLATFORM${RESET}"
echo ""

echo "📚 Reference files (all platforms)..."
copy_item "$SRC_DIR/abp-dev" "$TARGET_DIR"

if [[ "$PLATFORM" == "all" || "$PLATFORM" == "copilot" ]]; then
  echo ""
  echo "🤖 GitHub Copilot..."
  copy_item "$SRC_DIR/.github" "$TARGET_DIR"
fi

if [[ "$PLATFORM" == "all" || "$PLATFORM" == "claude" ]]; then
  echo ""
  echo "🧠 Claude Code..."
  copy_item "$SRC_DIR/.claude"   "$TARGET_DIR"
  copy_item "$SRC_DIR/CLAUDE.md" "$TARGET_DIR"
fi

if [[ "$PLATFORM" == "all" || "$PLATFORM" == "windsurf" ]]; then
  echo ""
  echo "🌊 Windsurf..."
  copy_item "$SRC_DIR/.windsurf"     "$TARGET_DIR"
  copy_item "$SRC_DIR/.windsurfrules" "$TARGET_DIR"
fi

if [[ "$PLATFORM" == "all" || "$PLATFORM" == "continue" ]]; then
  echo ""
  echo "▶  Continue.dev..."
  copy_item "$SRC_DIR/.continue" "$TARGET_DIR"
fi

# ── done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}✅ ABP AI Skills installed successfully!${RESET}"
echo ""
echo "Next steps — open your project and describe your feature:"
[[ "$PLATFORM" == "all" || "$PLATFORM" == "copilot"  ]] && \
  echo "  Copilot    → attach #abp-super.prompt.md → describe your feature"
[[ "$PLATFORM" == "all" || "$PLATFORM" == "claude"   ]] && \
  echo "  Claude Code → /project:abp-super Build a product catalog with Razor Pages UI"
[[ "$PLATFORM" == "all" || "$PLATFORM" == "windsurf" ]] && \
  echo "  Windsurf   → run workflow abp-super"
[[ "$PLATFORM" == "all" || "$PLATFORM" == "continue" ]] && \
  echo "  Continue.dev → select ABP Super Agent from the agent picker"
echo ""

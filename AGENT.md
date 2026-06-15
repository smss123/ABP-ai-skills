# AGENT.md — Machine-readable install instructions for AI agents

This file tells any AI coding assistant how to install ABP AI Skills into an ABP project.

---

## What this repository provides

- **38 reference files** in `abp-dev/references/` — curated ABP Framework patterns
- **Agent commands** for Claude Code, GitHub Copilot, Windsurf, and Continue.dev
- **Install scripts**: `install.sh` (bash) and `install.ps1` (PowerShell)

---

## How to install into an ABP project

### Option 1 — Bash (macOS / Linux / WSL / Git Bash)

```bash
# Install all platforms
bash install.sh /path/to/abp-project --overwrite

# Install for a specific AI tool only
bash install.sh /path/to/abp-project --platform claude   --overwrite
bash install.sh /path/to/abp-project --platform copilot  --overwrite
bash install.sh /path/to/abp-project --platform windsurf --overwrite
bash install.sh /path/to/abp-project --platform continue --overwrite
```

### Option 2 — PowerShell (Windows)

```powershell
.\install.ps1 C:\path\to\abp-project -Overwrite
.\install.ps1 C:\path\to\abp-project -Platform claude -Overwrite
```

### Option 3 — Make

```bash
make install  TARGET=/path/to/abp-project
make claude   TARGET=/path/to/abp-project
make copilot  TARGET=/path/to/abp-project
```

### Option 4 — One-liner (no clone needed)

```bash
curl -sSL https://raw.githubusercontent.com/smss123/ABP-ai-skills/main/install.sh \
  | bash -s -- /path/to/abp-project --overwrite
```

---

## What gets installed

| Item | Destination | Condition |
|---|---|---|
| `abp-dev/references/` | `<target>/abp-dev/references/` | Always |
| `.claude/` + `CLAUDE.md` | `<target>/` | Platform `all` or `claude` |
| `.github/` | `<target>/` | Platform `all` or `copilot` |
| `.windsurf/` + `.windsurfrules` | `<target>/` | Platform `all` or `windsurf` |
| `.continue/` | `<target>/` | Platform `all` or `continue` |

---

## After installation — activate the Super Agent

| Platform | Command |
|---|---|
| **Claude Code** | `/project:abp-super Build a product catalog with Razor Pages UI` |
| **GitHub Copilot** | Attach `#abp-super.prompt.md` → describe your feature |
| **Windsurf** | `run workflow abp-super` in Cascade |
| **Continue.dev** | Select **ABP Super Agent** from the agent picker |

---

## AI agent instructions (for self-installation)

If you are an AI agent reading this file and the user asks you to set up ABP AI Skills in the current project:

1. Check if `abp-dev/references/` already exists in the project root — if yes, skip or ask to overwrite.
2. Determine the OS (bash → `install.sh`, PowerShell → `install.ps1`).
3. Run the appropriate install script with `--overwrite` and the project root as the target.
4. Confirm which files were copied.
5. Tell the user the activation command for their AI tool (see table above).

---
mode: 'agent'
description: 'Install ABP AI Skills into an ABP project — detect the platform files already present, back up what exists, run the installer, and report what landed and how to activate the super agent'
tools: ['codebase', 'search', 'runCommands', 'editFiles']
---

Install the ABP AI Skills reference files and agent commands into a target ABP project directory.

## Steps

1. **Read the arguments** from `$ARGUMENTS`:
   - first positional value → target directory (may be empty)
   - `--platform <all|claude|copilot|windsurf|continue>` → defaults to `all`

2. **If no target directory was given**, ask:
   > "Please provide the full path to your ABP project directory:"

3. **Verify the directory exists** and that it looks like a .NET project (`*.sln`, `*.csproj`, or a
   `src/` folder). If it does not exist, say so and stop.

4. **Check for existing skill files before overwriting** — `abp-dev/`, `AGENTS.md`, `CLAUDE.md`,
   `.claude/`, `.github/prompts/`, `.windsurf/`, `.windsurfrules`, `.continue/`. If any exist, show the
   list and ask the user whether to back them up (copy to `<file>.bak-<date>`) or overwrite. Never
   silently replace a project's own `CLAUDE.md`, `.windsurfrules` or `.continue/config.yaml` — those
   frequently carry hand-written project rules.

5. **Run the installer** from the root of this repository:
   ```bash
   bash install.sh "<target-directory>" --platform <platform> --overwrite
   ```
   On Windows PowerShell:
   ```powershell
   .\install.ps1 "<target-directory>" -Platform <platform> -Overwrite
   ```
   If the script is not present (the user is in their own project, not in the skills repo), use the
   one-liner instead:
   ```bash
   curl -sSL https://raw.githubusercontent.com/smss123/ABP-ai-skills/main/install.sh \
     | bash -s -- "<target-directory>" --platform <platform> --overwrite
   ```

6. **Report what landed** — list the folders/files actually copied, then give the activation line for
   each platform installed:
   - **Any AGENTS.md-aware tool** (Copilot coding agent, Codex, Cursor, Zed, Qoder, Amp, Jules): nothing
     to attach — `AGENTS.md` is loaded and Phase 0 runs on ABP detection.
   - **Claude Code**: `/project:abp-super Build a product catalog with Razor Pages UI`
   - **Copilot Chat**: attach `#abp-super.prompt.md`, then describe the feature
   - **Windsurf**: run the `abp-super` workflow in Cascade
   - **Continue.dev**: select **ABP Super Agent** in the agent picker

7. **Suggest the first verification**: `bash scripts/verify-skill.sh` in this repository (structure and
   routing checks), or in the installed project just confirm `abp-dev/references/INDEX.md` is reachable.

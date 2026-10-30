---
name: abp-install
description: Install ABP AI Skills into an ABP project — detect what already exists, back up hand-written instruction files, run the installer, and report what landed plus the activation command
---

# ABP AI Skills — Install into an ABP Project

A Windsurf Cascade workflow that installs the reference files and agent workflows into a target ABP
project.

## Inputs

1. **Target directory** — full path to the ABP project root
2. **Platform** — `all` (default), `claude`, `copilot`, `windsurf`, `continue`

## Step 1 — Validate the target

- the directory must exist and look like a .NET solution (`*.sln`, `*.csproj`, or a `src/` folder)
- if it does not exist, report that and stop

## Step 2 — Check what is already there

Look for `abp-dev/`, `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.github/prompts/`, `.github/instructions/`,
`.windsurf/`, `.windsurfrules`, `.continue/`. If any exist, list them and ask whether to **back up**
(copy to `<file>.bak-<date>`) or overwrite. Never silently replace a project's own `CLAUDE.md`,
`.windsurfrules` or `.continue/config.yaml` — they usually hold hand-written project rules.

## Step 3 — Run the installer

From the root of this repository:
```bash
bash install.sh "<target-directory>" --platform <platform> --overwrite
```
Windows PowerShell:
```powershell
.\install.ps1 "<target-directory>" -Platform <platform> -Overwrite
```
If `install.sh` is not present (the user is inside their own project rather than the skills repo), use
the one-liner:
```bash
curl -sSL https://raw.githubusercontent.com/smss123/ABP-ai-skills/main/install.sh \
  | bash -s -- "<target-directory>" --platform <platform> --overwrite
```

## Step 4 — Report

List the folders/files actually copied, then give the activation line per installed platform:

| Platform | First command |
|---|---|
| AGENTS.md-aware tools (Copilot coding agent, Codex, Cursor, Zed, Qoder…) | nothing — `AGENTS.md` loads and Phase 0 runs on ABP detection |
| Claude Code | `/project:abp-super Build a product catalog with Razor Pages UI` |
| GitHub Copilot Chat | attach `#abp-super.prompt.md`, describe the feature |
| Windsurf | run the `abp-super` workflow |
| Continue.dev | select **ABP Super Agent** |

## Step 5 — Suggest verification

In the skills repository: `bash scripts/verify-skill.sh` (routing, parity and ABP-rule checks).
In the installed project: confirm `abp-dev/references/INDEX.md` exists and is reachable.

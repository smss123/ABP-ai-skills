# ABP AI Skills — Install into an ABP Project

Install the ABP AI Skills reference files and agent commands into a target ABP project directory.

## Usage

```
/project:abp-install [target-directory] [--platform all|claude|copilot|windsurf|continue]
```

**Examples:**
- `/project:abp-install /Users/me/MyApp` — install all platforms
- `/project:abp-install /Users/me/MyApp --platform claude` — Claude Code only
- `/project:abp-install` — you will be prompted for the target path

---

## Instructions for the AI agent

When this command is invoked:

1. **Extract arguments** from `$ARGUMENTS`:
   - First positional value = target directory path (may be empty)
   - `--platform <value>` = platform filter (default: `all`)

2. **If target directory is not provided**, ask the user:
   > "Please provide the full path to your ABP project directory:"

3. **Verify the target directory exists.** If it does not, tell the user and stop.

4. **Run the install script** from the root of this repository:
   ```bash
   bash install.sh "<target-directory>" --platform <platform> --overwrite
   ```

5. **Report the result** — list which folders/files were copied and what the next step is for their chosen platform:
   - **Claude Code**: Open the project and run `/project:abp-super <your feature description>`
   - **Copilot**: Attach `#abp-super.prompt.md` in a chat and describe your feature
   - **Windsurf**: Run the `abp-super` workflow in Cascade
   - **Continue.dev**: Select **ABP Super Agent** from the agent picker

$ARGUMENTS

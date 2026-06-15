# install.ps1 — ABP AI Skills installer (Windows PowerShell)
# Usage:
#   .\install.ps1 C:\path\to\your-abp-project
#   .\install.ps1 C:\path\to\your-abp-project -Platform claude
#
# Remote (no clone needed):
#   irm https://raw.githubusercontent.com/smss123/ABP-ai-skills/main/install.ps1 | iex
#   # Then you will be prompted for the target directory

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetDir,

    [ValidateSet('all', 'copilot', 'claude', 'windsurf', 'continue')]
    [string]$Platform = 'all',

    [switch]$Overwrite
)

$RepoUrl    = 'https://github.com/smss123/ABP-ai-skills.git'
$RepoBranch = 'main'

function Write-Banner {
    Write-Host ''
    Write-Host '╔══════════════════════════════════════════════════╗' -ForegroundColor Cyan
    Write-Host '║         ABP AI Skills — Auto Installer           ║' -ForegroundColor Cyan
    Write-Host '║  GitHub Copilot · Claude Code · Windsurf         ║' -ForegroundColor Cyan
    Write-Host '║  Continue.dev  · any AI assistant                ║' -ForegroundColor Cyan
    Write-Host '╚══════════════════════════════════════════════════╝' -ForegroundColor Cyan
    Write-Host ''
}

function Copy-Item-Safe {
    param([string]$Src, [string]$DestParent)
    $name = Split-Path $Src -Leaf
    $dest = Join-Path $DestParent $name

    if ((Test-Path $dest) -and -not $Overwrite) {
        $confirm = Read-Host "  '$name' already exists. Overwrite? [y/N]"
        if ($confirm -notmatch '^[Yy]$') {
            Write-Host "  [skipped] $name" -ForegroundColor Yellow
            return
        }
    }

    if (Test-Path $Src -PathType Container) {
        Copy-Item -Path $Src -Destination $dest -Recurse -Force
    } else {
        Copy-Item -Path $Src -Destination $dest -Force
    }
    Write-Host "  [OK] $name" -ForegroundColor Green
}

# ── prompt for target if not provided ────────────────────────────────────────
if (-not $TargetDir) {
    $TargetDir = Read-Host 'Enter path to your ABP project directory'
}

$TargetDir = $TargetDir.Trim().Trim('"')
if (-not (Test-Path $TargetDir -PathType Container)) {
    Write-Host "Error: Directory '$TargetDir' does not exist." -ForegroundColor Red
    exit 1
}

# ── locate source ─────────────────────────────────────────────────────────────
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$SrcDir    = $null
$TempDir   = $null

if ((Test-Path (Join-Path $ScriptDir 'CLAUDE.md')) -and
    (Test-Path (Join-Path $ScriptDir 'abp-dev\references'))) {
    $SrcDir = $ScriptDir
    Write-Host "Using local repo: $SrcDir" -ForegroundColor Green
} else {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Error: 'git' is required. Install Git for Windows and try again." -ForegroundColor Red
        exit 1
    }
    $TempDir = Join-Path $env:TEMP ('abp-ai-skills-' + [System.IO.Path]::GetRandomFileName())
    Write-Host 'Downloading ABP AI Skills...' -ForegroundColor Cyan
    git clone --depth 1 --branch $RepoBranch $RepoUrl $TempDir --quiet
    $SrcDir = $TempDir
    Write-Host 'Downloaded.' -ForegroundColor Green
}

# ── install ───────────────────────────────────────────────────────────────────
Write-Banner
Write-Host "Target : $TargetDir" -ForegroundColor Yellow
Write-Host "Platform: $Platform"  -ForegroundColor Yellow
Write-Host ''

Write-Host 'Reference files (all platforms)...'
Copy-Item-Safe (Join-Path $SrcDir 'abp-dev') $TargetDir

if ($Platform -in 'all', 'copilot') {
    Write-Host ''; Write-Host 'GitHub Copilot...'
    Copy-Item-Safe (Join-Path $SrcDir '.github') $TargetDir
}

if ($Platform -in 'all', 'claude') {
    Write-Host ''; Write-Host 'Claude Code...'
    Copy-Item-Safe (Join-Path $SrcDir '.claude')   $TargetDir
    Copy-Item-Safe (Join-Path $SrcDir 'CLAUDE.md') $TargetDir
}

if ($Platform -in 'all', 'windsurf') {
    Write-Host ''; Write-Host 'Windsurf...'
    Copy-Item-Safe (Join-Path $SrcDir '.windsurf')      $TargetDir
    Copy-Item-Safe (Join-Path $SrcDir '.windsurfrules') $TargetDir
}

if ($Platform -in 'all', 'continue') {
    Write-Host ''; Write-Host 'Continue.dev...'
    Copy-Item-Safe (Join-Path $SrcDir '.continue') $TargetDir
}

# ── cleanup temp ──────────────────────────────────────────────────────────────
if ($TempDir -and (Test-Path $TempDir)) {
    Remove-Item -Recurse -Force $TempDir
}

# ── done ──────────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host 'ABP AI Skills installed successfully!' -ForegroundColor Green
Write-Host ''
Write-Host 'Next steps — open your project and describe your feature:'
if ($Platform -in 'all', 'copilot')  { Write-Host '  Copilot     -> attach #abp-super.prompt.md -> describe your feature' }
if ($Platform -in 'all', 'claude')   { Write-Host '  Claude Code -> /project:abp-super Build a product catalog with Razor Pages UI' }
if ($Platform -in 'all', 'windsurf') { Write-Host '  Windsurf    -> run workflow abp-super' }
if ($Platform -in 'all', 'continue') { Write-Host '  Continue.dev -> select ABP Super Agent from the agent picker' }
Write-Host ''

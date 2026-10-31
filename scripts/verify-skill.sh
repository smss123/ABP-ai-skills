#!/usr/bin/env bash
# verify-skill.sh — self-verification harness for ABP AI Skills
#
#   bash scripts/verify-skill.sh              # offline structural checks (used by CI)
#   bash scripts/verify-skill.sh --links      # also HEAD-check every documentation URL
#   make verify
#
# Each check exists because of a real drift bug that already happened in this repo:
# routing tables that named files which did not exist, reference files no instruction file
# pointed at, per-platform copies of the same rule disagreeing, and hardcoded file counts.

set -uo pipefail

# Run from the repository root (make verify and CI both do).
if [[ ! -f abp-dev/references/INDEX.md ]]; then
  printf 'Run this script from the repository root: bash scripts/verify-skill.sh\n' >&2
  exit 2
fi

CHECK_LINKS=false
[[ "${1:-}" == "--links" ]] && CHECK_LINKS=true

FAILURES=0
WARNINGS=0

pass() { printf '  \033[0;32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$1"; FAILURES=$((FAILURES + 1)); }
warn() { printf '  \033[1;33m!\033[0m %s\n' "$1"; WARNINGS=$((WARNINGS + 1)); }
head2() { printf '\n\033[0;36m%s\033[0m\n' "$1"; }
# Line count of a possibly-empty list (wc -l would report 1 for the empty string).
id_count() { printf '%s\n' "$1" | grep -c '[^[:space:]]'; }

REF_DIR="abp-dev/references"
INDEX="$REF_DIR/INDEX.md"

# Files an ABP-aware agent loads without being asked to.
ALWAYS_LOADED="
AGENTS.md
CLAUDE.md
.windsurfrules
.github/copilot-instructions.md
.github/instructions/abp.instructions.md
.continue/config.yaml
abp-dev/SKILL.md
$INDEX
"

# ── 1. routing: INDEX.md ↔ reference files, both directions ──────────────────
head2 "1. Reference routing ($INDEX)"

if [[ ! -f "$INDEX" ]]; then
  fail "INDEX.md is missing — nothing can be routed"
else
  # Only table rows route; prose may mention CLAUDE.md etc. without meaning a reference file.
  named=$(grep '^|' "$INDEX" | grep -oE '`[a-zA-Z0-9_-]+\.md`' | tr -d '`' | sort -u)
  present=$(ls "$REF_DIR"/*.md 2>/dev/null | xargs -n1 basename | sort -u)

  missing=0
  for f in $named; do
    [[ -f "$REF_DIR/$f" ]] || { fail "INDEX.md routes to $f, which does not exist"; missing=$((missing + 1)); }
  done
  [[ $missing -eq 0 ]] && pass "every file INDEX.md names exists"

  # INDEX.md names nothing that isn't a reference file, so exclusions are explicit.
  orphans=""
  for f in $present; do
    [[ "$f" == "INDEX.md" ]] && continue
    grep -q "\`$f\`" "$INDEX" || orphans="$orphans $f"
  done
  if [[ -n "$orphans" ]]; then
    for f in $orphans; do fail "$f exists but INDEX.md never routes to it (unreachable)"; done
  else
    pass "every reference file is reachable through INDEX.md"
  fi

  total=$(id_count "$present")
  pass "reference files on disk: $total"
fi

# ── 2. agent capability parity across platforms ──────────────────────────────
head2 "2. Agent/capability parity across the four platforms"

copilot_ids=$(ls .github/prompts/*.prompt.md 2>/dev/null | xargs -n1 basename | sed 's/\.prompt\.md$//' | sort)
claude_ids=$(ls .claude/commands/*.md 2>/dev/null | xargs -n1 basename | sed 's/\.md$//' | sort)
windsurf_ids=$(ls .windsurf/workflows/*.md 2>/dev/null | xargs -n1 basename | sed 's/\.md$//' | sort)
# Continue identifies agents by display name; `# id:` comments make the set machine-checkable.
continue_ids=$(grep -oE '#[[:space:]]*id:[[:space:]]*abp-[a-z0-9-]+' .continue/config.yaml 2>/dev/null \
  | sed -E 's/.*id:[[:space:]]*//' | sort)

union=$(printf '%s\n%s\n%s\n%s\n' "$copilot_ids" "$claude_ids" "$windsurf_ids" "$continue_ids" \
  | grep -v '^$' | sort -u)
union_count=$(id_count "$union")

compare_platform() {
  local label="$1" ids="$2"
  local missing extra
  missing=$(comm -23 <(echo "$union") <(echo "$ids"))
  extra=$(comm -13 <(echo "$union") <(echo "$ids"))
  if [[ -n "$missing" ]]; then
    for c in $missing; do fail "$label has no '$c'"; done
  fi
  if [[ -n "$extra" ]]; then
    for c in $extra; do fail "$label exposes '$c' that no other platform has"; done
  fi
  if [[ -z "$missing" && -z "$extra" ]]; then
    pass "$label: all $union_count capabilities"
  fi
}

compare_platform "GitHub Copilot (.github/prompts)"   "$copilot_ids"
compare_platform "Claude Code (.claude/commands)"      "$claude_ids"
compare_platform "Windsurf (.windsurf/workflows)"      "$windsurf_ids"
compare_platform "Continue.dev (.continue/config.yaml)" "$continue_ids"

if [[ -z "$continue_ids" ]]; then
  fail ".continue/config.yaml has no '# id: abp-*' markers — parity cannot be checked"
fi

# Docs may state the capability count; it must equal the real number.
claims_before=$FAILURES
for doc in README.md AGENT.md AGENTS.md abp-dev/SKILL.md; do
  [[ -f "$doc" ]] || continue
  for claimed in $(grep -oE '[0-9]+ (ABP )?capabilities' "$doc" 2>/dev/null | grep -oE '^[0-9]+'); do
    if [[ "$claimed" != "$union_count" ]]; then
      fail "$doc claims $claimed capabilities, the real number is $union_count"
    fi
  done
  # Per-platform counts drift the moment one agent is added: check each claim against disk.
  while IFS= read -r hit; do
    line=${hit%%:*}
    claimed=$(printf '%s' "$hit" | grep -oE '[0-9]+ ([a-z]+ ){0,2}(prompts|commands|workflows|agents)' | grep -oE '^[0-9]+')
    kind=$(printf '%s' "$hit"   | grep -oE '(prompts|commands|workflows|agents)' | tail -1)
    case "$kind" in
      prompts)   real=$(id_count "$copilot_ids")  ;;
      commands)  real=$(id_count "$claude_ids")   ;;
      workflows) real=$(id_count "$windsurf_ids") ;;
      agents)    real=$(id_count "$continue_ids") ;;
      *)         real="$claimed" ;;
    esac
    [[ -n "$claimed" ]] || continue
    [[ "$claimed" == "$real" ]] \
      || fail "$doc:$line claims $claimed $kind, the folder has $real"
  done < <(grep -nE '[0-9]+ ([a-z]+ ){0,2}(prompts|commands|workflows|agents)\b' "$doc" 2>/dev/null)
done
[[ $FAILURES -eq $claims_before ]] && pass "documented agent/capability counts match what is on disk ($union_count)"

# ── 3. Phase 0 + auto-activation in every always-loaded file ─────────────────
head2 "3. Phase 0 and auto-activation are present"

phase0_before=$FAILURES
for f in $ALWAYS_LOADED; do
  if [[ ! -f "$f" ]]; then
    fail "expected always-loaded file missing: $f"
    continue
  fi
  if ! grep -q "Phase 0" "$f"; then
    fail "$f never mentions Phase 0 context intake"
  fi
  if ! grep -q "context-intake.md" "$f"; then
    fail "$f does not route to references/context-intake.md"
  fi
done
[[ $FAILURES -eq $phase0_before ]] && pass "Phase 0 + context-intake.md referenced in every always-loaded file"

# Detection signals must live in exactly one place (context-intake.md §0.0); the
# always-on entry points may quote them but must point back at the authority.
detect_before=$FAILURES
for f in AGENTS.md CLAUDE.md .windsurfrules .github/copilot-instructions.md .github/instructions/abp.instructions.md .continue/config.yaml; do
  grep -q "Volo.Abp" "$f" || fail "$f lists no ABP detection signal — it cannot auto-activate"
  grep -qE "context-intake\.md|§0\.0" "$f" || fail "$f does not defer to context-intake.md §0.0 for detection"
done
[[ $FAILURES -eq $detect_before ]] && pass "detection signals present and delegated to §0.0"

# ── 4. no hardcoded counts ───────────────────────────────────────────────────
head2 "4. No hardcoded reference counts"

count_hits=$(grep -rnEi '[0-9]+ (curated )?reference files?|[0-9]+ of them|all [0-9]+ references' \
  --include='*.md' --include='*.yaml' --include='*.yml' --include='*.prompt.md' \
  AGENTS.md AGENT.md CLAUDE.md README.md .windsurfrules .github .claude .continue .windsurf "$REF_DIR" 2>/dev/null)
if [[ -n "$count_hits" ]]; then
  while IFS= read -r line; do fail "hardcoded count (say 'every file in references/'): $line"; done <<< "$count_hits"
else
  pass "no file counts to drift"
fi

# ── 5. forbidden patterns inside reference code samples ─────────────────────
head2 "5. ABP anti-patterns in code samples"

bad_guid=$(grep -rn "Guid\.NewGuid()" "$REF_DIR" 2>/dev/null \
  | grep -viE "never|instead of|don't|do not|avoid|not |use IGuidGenerator|use GuidGenerator")
if [[ -n "$bad_guid" ]]; then
  while IFS= read -r line; do fail "Guid.NewGuid() presented as guidance: $line"; done <<< "$bad_guid"
else
  pass "no Guid.NewGuid() recommended (IGuidGenerator / GuidGenerator.Create() only)"
fi

bad_throw=$(grep -rn "throw new Exception(" "$REF_DIR" 2>/dev/null)
if [[ -n "$bad_throw" ]]; then
  while IFS= read -r line; do fail "raw Exception instead of BusinessException: $line"; done <<< "$bad_throw"
else
  pass "domain rule violations use BusinessException"
fi

grep -q "ConfigureByConvention" "$REF_DIR/efcore.md" \
  || fail "efcore.md does not mandate ConfigureByConvention()"

# ── 6. installers ────────────────────────────────────────────────────────────
head2 "6. Installers"

if bash -n install.sh 2>/dev/null; then pass "install.sh parses"; else fail "install.sh has a syntax error"; fi

copy_srcs=$(grep -oE 'copy_item "\$SRC_DIR/[^"]+"' install.sh | sed -E 's|.*"\$SRC_DIR/([^"]+)"|\1|' | sort -u)
copies_before=$FAILURES
for item in $copy_srcs; do
  [[ -e "$item" ]] || fail "install.sh copies $item, which is not in the repo"
done
[[ $FAILURES -eq $copies_before ]] && pass "every install.sh source path exists ($(echo "$copy_srcs" | wc -l | tr -d ' ') items)"

if command -v pwsh >/dev/null 2>&1; then
  if pwsh -NoProfile -Command '
    $tokens = $null; $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile("install.ps1", [ref]$tokens, [ref]$errors)
    if ($errors) { $errors | ForEach-Object { Write-Error $_.Message }; exit 1 }
  ' >/dev/null 2>&1; then
    pass "install.ps1 parses"
  else
    fail "install.ps1 has a syntax error"
  fi
else
  warn "pwsh unavailable — install.ps1 not parsed"
fi

# ── 7. documentation URLs ────────────────────────────────────────────────────
head2 "7. Documentation URLs"

bad_urls=$(grep -ohE 'https?://[^ )`,">]+' "$INDEX" | grep -vE '^https://(abp\.io|docs\.abp\.io)/' | sort -u)
if [[ -n "$bad_urls" ]]; then
  while IFS= read -r u; do fail "INDEX.md links outside abp.io: $u"; done <<< "$bad_urls"
else
  pass "every INDEX.md link is an official abp.io documentation URL"
fi

if [[ "$CHECK_LINKS" == true ]]; then
  echo "  … checking link liveness"
  dead=0
  for u in $(grep -ohE 'https://(docs\.)?abp\.io/[^ )`">,]+' "$INDEX" $REF_DIR/*.md | sed 's/[.,]$//' | sort -u); do
    code=$(curl -s -o /dev/null -L --max-time 20 -w '%{http_code}' "$u" || echo "000")
    if [[ "$code" != "200" ]]; then
      fail "HTTP $code: $u"
      dead=$((dead + 1))
    fi
  done
  [[ $dead -eq 0 ]] && pass "all documentation URLs return 200"
fi

# ── 8. freshness metadata ────────────────────────────────────────────────────
head2 "8. Version-freshness metadata (reference files)"

no_fm=""
unverified=0
fm_before=$FAILURES
for f in "$REF_DIR"/*.md; do
  [[ "$(basename "$f")" == "INDEX.md" ]] && continue
  first=$(head -1 "$f")
  if [[ "$first" != "---" ]]; then
    no_fm="$no_fm $(basename "$f")"
    continue
  fi
  fm=$(awk 'NR==1{next} /^---$/{exit} {print}' "$f")
  echo "$fm" | grep -q "^applies_to_abp:" || fail "$(basename "$f") frontmatter lacks applies_to_abp"
  echo "$fm" | grep -q "^doc_verified_on:" || fail "$(basename "$f") frontmatter lacks doc_verified_on"
  v=$(echo "$fm" | grep -E '^doc_verified_on:' | sed 's/.*:[[:space:]]*//' | tr -d '"')
  case "$v" in
    unverified) unverified=$((unverified + 1)) ;;
    n/a)  # only legitimate for a file that cites no documentation URL of its own
      if grep -qE 'https://(docs\.)?abp\.io/' "$f"; then
        fail "$(basename "$f") cites abp.io URLs but declares doc_verified_on: n/a"
      fi
      ;;
    "")   fail "$(basename "$f") has an empty doc_verified_on" ;;
    *)    [[ "$v" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || fail "$(basename "$f") doc_verified_on is not YYYY-MM-DD: $v" ;;
  esac
done
if [[ -n "$no_fm" ]]; then
  fail "missing freshness frontmatter in:$no_fm"
elif [[ $FAILURES -eq $fm_before ]]; then
  pass "every reference file declares applies_to_abp + doc_verified_on"
fi
if [[ $unverified -gt 0 ]]; then
  warn "$unverified reference file(s) marked doc_verified_on: unverified — fetch the docs URL and date them"
elif [[ -z "$no_fm" && $FAILURES -eq $fm_before ]]; then
  pass "no reference file is awaiting documentation verification"
fi

# ── summary ──────────────────────────────────────────────────────────────────
echo
if [[ $FAILURES -eq 0 ]]; then
  printf '\033[0;32m✅ skill structure verified\033[0m (%d warning(s))\n' "$WARNINGS"
  exit 0
fi
printf '\033[0;31m❌ %d problem(s)\033[0m (%d warning(s))\n' "$FAILURES" "$WARNINGS"
exit 1

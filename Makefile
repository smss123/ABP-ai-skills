.DEFAULT_GOAL := help

# Override on the command line: make install TARGET=/path/to/abp-project
TARGET   ?=
PLATFORM ?= all

help:
	@echo ""
	@echo "  ABP AI Skills — Install Targets"
	@echo ""
	@echo "  make install   TARGET=/path/to/abp-project [PLATFORM=all|claude|copilot|windsurf|continue]"
	@echo "  make claude    TARGET=/path/to/abp-project"
	@echo "  make copilot   TARGET=/path/to/abp-project"
	@echo "  make windsurf  TARGET=/path/to/abp-project"
	@echo "  make continue  TARGET=/path/to/abp-project"
	@echo ""
	@echo "  make verify    Check routing, platform parity and ABP rules in the skill itself"
	@echo "  make links     Also HEAD-check every documentation URL (needs network)"
	@echo ""

install:
	@if [ -z "$(TARGET)" ]; then \
	  echo "Error: TARGET is required.  make install TARGET=/path/to/abp-project"; \
	  exit 1; \
	fi
	@bash install.sh "$(TARGET)" --platform $(PLATFORM) --overwrite

claude:
	@$(MAKE) install PLATFORM=claude

copilot:
	@$(MAKE) install PLATFORM=copilot

windsurf:
	@$(MAKE) install PLATFORM=windsurf

continue:
	@$(MAKE) install PLATFORM=continue

# Structural self-check of the skill — routing, parity, Phase 0, ABP rules, installers.
verify:
	@bash scripts/verify-skill.sh

# Same, plus a live HEAD request against every documentation URL.
links:
	@bash scripts/verify-skill.sh --links

.PHONY: help install claude copilot windsurf continue verify links

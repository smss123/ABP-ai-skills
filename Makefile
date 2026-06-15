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

.PHONY: help install claude copilot windsurf continue

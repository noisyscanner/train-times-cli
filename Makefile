# Install train_cli.py as a `trains` command for the current user.
#
#   make install     -> ~/.local/share/train-times-cli/{venv,train_cli.py}
#                       ~/.local/bin/trains  (launcher, executable)
#   make uninstall   -> removes both
#
# Needs Python >= 3.10 (requirements.txt pins click 8.3). Uses uv when
# installed, otherwise the newest python3.1x on PATH. Override with e.g.
#   make install PYTHON=/opt/homebrew/bin/python3.13 PREFIX=/opt/local NAME=train-times

PREFIX  ?= $(HOME)/.local
BINDIR  ?= $(PREFIX)/bin
NAME    ?= trains
PYTHON  ?= $(shell for p in python3.14 python3.13 python3.12 python3.11 python3.10; do command -v $$p >/dev/null 2>&1 && { echo $$p; break; }; done)
UV      := $(shell command -v uv 2>/dev/null)

APPDIR   := $(PREFIX)/share/train-times-cli
VENV     := $(APPDIR)/venv
VPY      := $(VENV)/bin/python
LAUNCHER := $(BINDIR)/$(NAME)

.PHONY: help install uninstall venv

help:
	@echo "make install    install '$(NAME)' into $(BINDIR) (venv in $(APPDIR))"
	@echo "make uninstall  remove the launcher and venv"
	@echo "Variables: PREFIX=$(PREFIX) BINDIR=$(BINDIR) NAME=$(NAME) PYTHON=$(or $(PYTHON),<none found>) UV=$(or $(UV),<not found>)"

$(VPY):
	mkdir -p "$(APPDIR)"
ifdef UV
	uv venv --quiet --python "$(or $(PYTHON),3.12)" "$(VENV)"
else
	@test -n "$(PYTHON)" || { echo "error: no Python >= 3.10 found; pass PYTHON=/path/to/python3.x"; exit 1; }
	"$(PYTHON)" -m venv "$(VENV)"
endif

venv: $(VPY)
ifdef UV
	uv pip install --quiet --python "$(VPY)" -r requirements.txt
else
	"$(VPY)" -m pip install --quiet --upgrade pip
	"$(VPY)" -m pip install --quiet -r requirements.txt
endif

install: venv
	install -m 644 train_cli.py "$(APPDIR)/train_cli.py"
	mkdir -p "$(BINDIR)"
	printf '#!/bin/sh\nexec "%s" "%s" "$$@"\n' "$(VPY)" "$(APPDIR)/train_cli.py" > "$(LAUNCHER)"
	chmod 755 "$(LAUNCHER)"
	@echo "Installed $(LAUNCHER)"
	@case ":$$PATH:" in *":$(BINDIR):"*) ;; *) echo "NOTE: $(BINDIR) is not on your PATH";; esac

uninstall:
	rm -f "$(LAUNCHER)"
	rm -rf "$(APPDIR)"
	@echo "Removed $(LAUNCHER) and $(APPDIR)"

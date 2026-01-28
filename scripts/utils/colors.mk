# ============================================================================
# CORES E FORMATAÇÃO
# ============================================================================
# Arquivo auxiliar para adicionar cores ao output do Makefile
# Compatível com: Ubuntu, WSL2, macOS
# ============================================================================

# Detecta se terminal suporta cores
TERM_COLORS := $(shell tput colors 2>/dev/null || echo 0)

ifeq ($(shell test $(TERM_COLORS) -ge 8 && echo yes),yes)
    BOLD := $(shell tput bold)
    GREEN := $(shell tput setaf 2)
    YELLOW := $(shell tput setaf 3)
    RED := $(shell tput setaf 1)
    BLUE := $(shell tput setaf 4)
    CYAN := $(shell tput setaf 6)
    RESET := $(shell tput sgr0)
else
    BOLD :=
    GREEN :=
    YELLOW :=
    RED :=
    BLUE :=
    CYAN :=
    RESET :=
endif

export BOLD GREEN YELLOW RED BLUE CYAN RESET

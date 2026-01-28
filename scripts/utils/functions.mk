# ============================================================================
# FUNÇÕES REUTILIZÁVEIS
# ============================================================================
# Funções auxiliares usadas pelo Makefile principal
# ============================================================================

# Função: Criar diretório de estado se não existir
define ensure-state-dir
	@mkdir -p $(STATE_DIR)
endef

# Função: Verificar se arquivo de flag existe
define check-flag
	@test -f $(1) || (echo "$(RED)❌ $(2)$(RESET)" && exit 1)
endef

# Função: Criar flag
define create-flag
	@mkdir -p $(STATE_DIR) && touch $(1)
endef

# Função: Remover flag
define remove-flag
	@rm -f $(1)
endef

# Função: Log com timestamp
define log
	@echo "[$(shell date +'%H:%M:%S')] $(1)"
endef

# Função: Executar comando com ou sem verbose
define run-cmd
	$(if $(filter 1,$(VERBOSE)),$(1),@$(1) $(QUIET) 2>&1)
endef

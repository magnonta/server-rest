# ============================================================================
# DEVOPS COURSE - MAKEFILE COMPLETO
# ============================================================================
# Automação completa do ambiente de testes de carga e segurança
# Curso: Pós-Graduação em QA - Testes de Carga e Segurança em CI/CD
#
# Compatível com: Ubuntu, WSL2, macOS
# 
# Uso básico:
#   make bootstrap    # Setup completo
#   make lab-aula-01  # Workflow Aula 01
#   make help         # Ver todos os comandos
#
# Customização:
#   cp .env.make.example .env.make
#   edit .env.make (ajustar variáveis)
# ============================================================================

# ============================================================================
# CONFIGURAÇÃO E VARIÁVEIS
# ============================================================================

# Carregar configurações personalizadas (se existir)
-include .env.make

# Modo verbose (padrão: desativado)
# Use: make bootstrap VERBOSE=1
VERBOSE ?= 0

# Detecção de sistema operacional
OS := $(shell uname -s)
ARCH := $(shell uname -m)

# Detecção de WSL2
IS_WSL := $(shell grep -qi microsoft /proc/version 2>/dev/null && echo "true" || echo "false")

# Diretórios de scripts
SCRIPTS_DIR := scripts
SETUP_SCRIPTS := $(SCRIPTS_DIR)/setup
K8S_SCRIPTS := $(SCRIPTS_DIR)/k8s
UTILS_SCRIPTS := $(SCRIPTS_DIR)/utils
LOAD_SCRIPTS := $(SCRIPTS_DIR)/load-testing
SECURITY_SCRIPTS := $(SCRIPTS_DIR)/security

# Configuração do Cluster kind
KIND_CLUSTER_NAME ?= serverest-cluster
KIND_CONFIG ?= k8s/kind/kind-config.yaml
KIND_WAIT_TIMEOUT ?= 3m

# Configuração Kubernetes
K8S_NAMESPACE ?= serverest
K8S_MANIFESTS_DIR ?= k8s/serverest
METRICS_SERVER_MANIFEST ?= k8s/kind/metrics-server.yaml

# Configuração k6
K6_SCRIPTS_DIR ?= k6/scripts
BASE_URL ?= http://localhost:30000

# Configuração Docker (ServeRest original)
NAME_IMAGE ?= paulogoncalvesbh/serverest

# Configuração de Segurança
TRIVY_VERSION ?= latest
ZAP_VERSION ?= latest

# Timeouts
POD_READY_TIMEOUT ?= 120s
HPA_READY_TIMEOUT ?= 60s
METRICS_WAIT_TIME ?= 30

# Arquivos de estado
STATE_DIR := .make-state
PORT_FORWARD_PID_FILE := $(STATE_DIR)/port-forward.pid
CLUSTER_CREATED_FLAG := $(STATE_DIR)/cluster-created
METRICS_INSTALLED_FLAG := $(STATE_DIR)/metrics-installed
DEPLOY_FLAG := $(STATE_DIR)/deployed

# Importar funções de cores e logging
-include $(UTILS_SCRIPTS)/colors.mk
-include $(UTILS_SCRIPTS)/functions.mk

# Flags de output
ifeq ($(VERBOSE),1)
    Q :=
    QUIET :=
else
    Q := @
    QUIET := --quiet
endif

# ============================================================================
# PRÉ-REQUISITOS E VALIDAÇÃO
# ============================================================================

.PHONY: check-prereqs check-all-tools install-guide install-tools

## check-prereqs: Verifica todas as ferramentas necessárias
check-prereqs:
	$(call log,$(BOLD)Verificando pré-requisitos...$(RESET))
	$(Q)bash $(SETUP_SCRIPTS)/verify-environment.sh

## check-all-tools: Alias para check-prereqs
check-all-tools: check-prereqs

## install-guide: Mostra guia de instalação personalizado para seu SO
install-guide:
	$(call log,$(BOLD)Guia de Instalação$(RESET))
	$(Q)bash $(SETUP_SCRIPTS)/show-install-guide.sh $(OS) $(IS_WSL)

## install-tools: Instala ferramentas automaticamente (requer sudo)
install-tools:
	$(call log,$(BOLD)Instalando ferramentas...$(RESET))
ifeq ($(OS),Darwin)
	$(Q)bash $(SETUP_SCRIPTS)/install-tools-macos.sh
else ifeq ($(IS_WSL),true)
	$(call log,$(YELLOW)WSL2 detectado - usando script Linux$(RESET))
	$(Q)bash $(SETUP_SCRIPTS)/install-tools-linux.sh
else ifeq ($(OS),Linux)
	$(Q)bash $(SETUP_SCRIPTS)/install-tools-linux.sh
else
	$(call log,$(RED)Sistema não suportado. Use Windows PowerShell:$(RESET))
	$(call log,$(YELLOW)  ./scripts/setup/install-tools-windows.ps1$(RESET))
	$(Q)exit 1
endif

# ============================================================================
# CLUSTER KUBERNETES (KIND)
# ============================================================================

.PHONY: cluster-create cluster-status cluster-delete cluster-logs cluster-restart cluster-info

## cluster-create: Cria cluster kind com 3 nodes
cluster-create: check-prereqs
	$(call ensure-state-dir)
	$(call log,$(BOLD)Criando cluster kind...$(RESET))
	$(Q)if kind get clusters 2>/dev/null | grep -q "^$(KIND_CLUSTER_NAME)$$"; then \
		echo "$(YELLOW)⚠️  Cluster já existe: $(KIND_CLUSTER_NAME)$(RESET)"; \
		echo "$(YELLOW)Use 'make cluster-delete' para remover$(RESET)"; \
		exit 1; \
	fi
	$(Q)kind create cluster \
		--name $(KIND_CLUSTER_NAME) \
		--config $(KIND_CONFIG) \
		--wait $(KIND_WAIT_TIMEOUT) \
		$(if $(filter 0,$(VERBOSE)),--quiet)
	$(call create-flag,$(CLUSTER_CREATED_FLAG))
	$(call log,$(GREEN)✅ Cluster criado!$(RESET))
	$(Q)echo ""
	$(Q)kubectl get nodes -o wide
	$(Q)echo ""
	$(call log,$(BOLD)Próximo passo:$(RESET) make metrics-install)

## cluster-status: Status detalhado do cluster
cluster-status:
	$(call log,$(BOLD)Status do Cluster$(RESET))
	$(Q)bash $(K8S_SCRIPTS)/cluster-status.sh $(KIND_CLUSTER_NAME) $(K8S_NAMESPACE)

## cluster-delete: Remove cluster completamente
cluster-delete:
	$(call log,$(BOLD)Removendo cluster...$(RESET))
	$(Q)if ! kind get clusters 2>/dev/null | grep -q "^$(KIND_CLUSTER_NAME)$$"; then \
		echo "$(YELLOW)⚠️  Cluster não existe$(RESET)"; \
		exit 0; \
	fi
	$(Q)kind delete cluster --name $(KIND_CLUSTER_NAME) $(if $(filter 0,$(VERBOSE)),--quiet)
	$(call remove-flag,$(CLUSTER_CREATED_FLAG))
	$(call remove-flag,$(METRICS_INSTALLED_FLAG))
	$(call remove-flag,$(DEPLOY_FLAG))
	$(call log,$(GREEN)✅ Cluster removido$(RESET))

## cluster-logs: Exporta logs do cluster
cluster-logs:
	$(call log,$(BOLD)Exportando logs...$(RESET))
	$(Q)mkdir -p /tmp/kind-logs
	$(Q)kind export logs \
		--name $(KIND_CLUSTER_NAME) \
		/tmp/kind-logs/$(KIND_CLUSTER_NAME)-$(shell date +%Y%m%d-%H%M%S)
	$(call log,$(GREEN)✅ Logs exportados para /tmp/kind-logs/$(RESET))

## cluster-restart: Reinicia cluster (delete + create)
cluster-restart: cluster-delete cluster-create
	$(call log,$(GREEN)✅ Cluster reiniciado$(RESET))

## cluster-info: Informações rápidas do cluster
cluster-info:
	$(call log,$(BOLD)Cluster Info$(RESET))
	$(Q)kubectl cluster-info --context kind-$(KIND_CLUSTER_NAME)
	$(Q)echo ""
	$(Q)kubectl get nodes

# ============================================================================
# DEPLOY DA APLICAÇÃO
# ============================================================================

.PHONY: metrics-install deploy deploy-check undeploy port-forward port-forward-stop api-test

## metrics-install: Instala Metrics Server
metrics-install:
	$(call check-flag,$(CLUSTER_CREATED_FLAG),Cluster não criado. Execute: make cluster-create)
	$(call log,$(BOLD)Instalando Metrics Server...$(RESET))
	$(Q)kubectl apply -f $(METRICS_SERVER_MANIFEST)
	$(call log,$(YELLOW)Aguardando Metrics Server...$(RESET))
	$(Q)bash $(K8S_SCRIPTS)/wait-for-pods.sh \
		kube-system \
		"k8s-app=metrics-server" \
		$(POD_READY_TIMEOUT)
	$(call log,$(YELLOW)Aguardando métricas ficarem disponíveis ($(METRICS_WAIT_TIME)s)...$(RESET))
	$(Q)sleep $(METRICS_WAIT_TIME)
	$(Q)bash $(K8S_SCRIPTS)/check-metrics.sh
	$(call create-flag,$(METRICS_INSTALLED_FLAG))
	$(call log,$(GREEN)✅ Metrics Server pronto!$(RESET))
	$(Q)echo ""
	$(call log,$(BOLD)Próximo passo:$(RESET) make deploy)

## deploy: Deploy completo do ServeRest
deploy:
	$(call check-flag,$(METRICS_INSTALLED_FLAG),Metrics Server não instalado. Execute: make metrics-install)
	$(call log,$(BOLD)Fazendo deploy do ServeRest...$(RESET))
	$(Q)kubectl apply -f $(K8S_MANIFESTS_DIR)/
	$(call log,$(YELLOW)Aguardando pods...$(RESET))
	$(Q)bash $(K8S_SCRIPTS)/wait-for-pods.sh \
		$(K8S_NAMESPACE) \
		"app=serverest" \
		$(POD_READY_TIMEOUT)
	$(call create-flag,$(DEPLOY_FLAG))
	$(call log,$(GREEN)✅ Deploy concluído!$(RESET))
	$(Q)echo ""
	$(Q)$(MAKE) deploy-check VERBOSE=0
	$(Q)echo ""
	$(call log,$(BOLD)Próximo passo:$(RESET) make port-forward)

## deploy-check: Verifica status do deploy
deploy-check:
	$(call log,$(BOLD)Status do Deploy$(RESET))
	$(Q)echo ""
	$(Q)echo "$(BOLD)Pods:$(RESET)"
	$(Q)kubectl get pods -n $(K8S_NAMESPACE)
	$(Q)echo ""
	$(Q)echo "$(BOLD)Services:$(RESET)"
	$(Q)kubectl get svc -n $(K8S_NAMESPACE)
	$(Q)echo ""
	$(Q)echo "$(BOLD)HPA:$(RESET)"
	$(Q)kubectl get hpa -n $(K8S_NAMESPACE)
	$(Q)echo ""
	$(Q)echo "$(BOLD)Recursos:$(RESET)"
	$(Q)kubectl top pods -n $(K8S_NAMESPACE) 2>/dev/null || \
		echo "$(YELLOW)Métricas ainda não disponíveis$(RESET)"

## undeploy: Remove deploy
undeploy:
	$(call log,$(BOLD)Removendo deploy...$(RESET))
	$(Q)kubectl delete -f $(K8S_MANIFESTS_DIR)/ --ignore-not-found=true
	$(call remove-flag,$(DEPLOY_FLAG))
	$(call log,$(GREEN)✅ Deploy removido$(RESET))

## port-forward: Inicia port-forward (background)
port-forward:
	$(call check-flag,$(DEPLOY_FLAG),Aplicação não deployada. Execute: make deploy)
	$(call ensure-state-dir)
	$(call log,$(BOLD)Iniciando port-forward...$(RESET))
	$(Q)bash $(K8S_SCRIPTS)/port-forward-manager.sh start \
		$(K8S_NAMESPACE) \
		serverest \
		30000 \
		3000 \
		$(PORT_FORWARD_PID_FILE)
	$(call log,$(GREEN)✅ Port-forward ativo: $(BASE_URL)$(RESET))
	$(Q)sleep 2
	$(Q)$(MAKE) api-test

## port-forward-stop: Para port-forward
port-forward-stop:
	$(call log,$(BOLD)Parando port-forward...$(RESET))
	$(Q)bash $(K8S_SCRIPTS)/port-forward-manager.sh stop $(PORT_FORWARD_PID_FILE)

## api-test: Testa API (requer port-forward ativo)
api-test:
	$(call log,$(BOLD)Testando API...$(RESET))
	$(Q)curl -s $(BASE_URL)/usuarios | head -5 || \
		echo "$(RED)❌ API não respondeu$(RESET)"

# ============================================================================
# TESTES DE CARGA (K6)
# ============================================================================

.PHONY: test-health test-smoke test-load-progressive test-stress test-spike test-soak test-load-all test-load test-load-suite

## test-health: Health check básico
test-health: check-prereqs
	$(call log,$(BOLD)Health Check$(RESET))
	$(Q)BASE_URL=$(BASE_URL) k6 run $(K6_SCRIPTS_DIR)/00-health-check.js \
		$(if $(filter 0,$(VERBOSE)),--quiet)

## test-smoke: Smoke test (1 VU)
test-smoke: check-prereqs
	$(call log,$(BOLD)Smoke Test$(RESET))
	$(Q)BASE_URL=$(BASE_URL) k6 run $(K6_SCRIPTS_DIR)/01-smoke-test.js \
		$(if $(filter 0,$(VERBOSE)),--quiet)

## test-load-progressive: Load test (10-20 VUs)
test-load-progressive: check-prereqs
	$(call log,$(BOLD)Load Test Progressivo$(RESET))
	$(Q)BASE_URL=$(BASE_URL) k6 run $(K6_SCRIPTS_DIR)/02-load-test.js

## test-stress: Stress test (até 300 VUs)
test-stress: check-prereqs
	$(call log,$(YELLOW)⚠️  Stress Test - Alta carga no sistema$(RESET))
	$(Q)BASE_URL=$(BASE_URL) k6 run $(K6_SCRIPTS_DIR)/03-stress-test.js

## test-spike: Spike test (picos de carga)
test-spike: check-prereqs
	$(call log,$(BOLD)Spike Test$(RESET))
	$(Q)BASE_URL=$(BASE_URL) k6 run $(K6_SCRIPTS_DIR)/04-spike-test.js

## test-soak: Soak test (30 minutos)
test-soak: check-prereqs
	$(call log,$(YELLOW)⚠️  Soak Test - Duração: 30 minutos$(RESET))
	$(call log,$(YELLOW)Pressione CTRL+C para cancelar$(RESET))
	$(Q)BASE_URL=$(BASE_URL) k6 run $(K6_SCRIPTS_DIR)/05-soak-test.js

## test-load-all: Todos os testes (exceto soak)
test-load-all: test-health test-smoke test-load-progressive test-stress test-spike
	$(call log,$(GREEN)✅ Suite de testes de carga concluída$(RESET))
	$(call log,$(YELLOW)Soak test (30min) não incluído$(RESET))

## test-load: Testes rápidos (health + smoke + load)
test-load: test-health test-smoke test-load-progressive
	$(call log,$(GREEN)✅ Testes rápidos concluídos$(RESET))

## test-load-suite: Executa suite via script externo (com relatório)
test-load-suite: check-prereqs
	$(call log,$(BOLD)Executando suite completa de testes k6$(RESET))
	$(Q)bash $(LOAD_SCRIPTS)/run-k6-suite.sh \
		$(BASE_URL) \
		$(K6_SCRIPTS_DIR) \
		$(VERBOSE)

# ============================================================================
# TESTES DE SEGURANÇA
# ============================================================================

.PHONY: test-security test-trivy test-trivy-image test-trivy-k8s test-zap security-report

## test-security: Todos os testes de segurança
test-security: test-trivy test-zap
	$(call log,$(GREEN)✅ Testes de segurança concluídos$(RESET))

## test-trivy: Scans Trivy (imagem + K8s)
test-trivy: test-trivy-image test-trivy-k8s

## test-trivy-image: Scan de vulnerabilidades na imagem
test-trivy-image:
	$(call log,$(BOLD)Trivy Image Scan$(RESET))
	$(Q)docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy:$(TRIVY_VERSION) image \
		--severity HIGH,CRITICAL \
		--format table \
		$(NAME_IMAGE):latest

## test-trivy-k8s: Scan de configurações Kubernetes
test-trivy-k8s:
	$(call log,$(BOLD)Trivy Kubernetes Scan$(RESET))
	$(Q)docker run --rm \
		-v $(PWD)/k8s:/k8s:ro \
		aquasec/trivy:$(TRIVY_VERSION) config \
		--severity HIGH,CRITICAL \
		--format table \
		/k8s

## test-zap: OWASP ZAP baseline scan
test-zap:
	$(call log,$(BOLD)OWASP ZAP Baseline Scan$(RESET))
	$(call log,$(YELLOW)Certifique-se de que $(BASE_URL) está acessível$(RESET))
	$(Q)docker run --rm \
		--network host \
		owasp/zap2docker-stable:$(ZAP_VERSION) \
		zap-baseline.py \
		-t $(BASE_URL) \
		-r /zap/wrk/zap-report.html

## security-report: Relatório consolidado
security-report:
	$(call log,$(BOLD)Gerando relatório de segurança$(RESET))
	$(Q)bash $(SECURITY_SCRIPTS)/run-all-scans.sh \
		$(NAME_IMAGE) \
		$(BASE_URL) \
		$(VERBOSE)
	$(call log,$(GREEN)✅ Relatórios em: security/reports/$(RESET))

# ============================================================================
# MONITORAMENTO E DEBUG
# ============================================================================

.PHONY: logs logs-follow describe-pod top watch-hpa watch-pods events debug-shell

## logs: Logs dos pods ServeRest
logs:
	$(call log,$(BOLD)Logs dos Pods$(RESET))
	$(Q)kubectl logs -n $(K8S_NAMESPACE) -l app=serverest --tail=50

## logs-follow: Logs em tempo real
logs-follow:
	$(call log,$(BOLD)Logs em Tempo Real (CTRL+C para parar)$(RESET))
	$(Q)kubectl logs -n $(K8S_NAMESPACE) -l app=serverest --follow

## describe-pod: Descreve pod específico (interativo)
describe-pod:
	$(Q)bash $(K8S_SCRIPTS)/describe-resource.sh pod $(K8S_NAMESPACE)

## top: Uso de recursos
top:
	$(call log,$(BOLD)Uso de Recursos$(RESET))
	$(Q)echo ""
	$(Q)echo "$(BOLD)Nodes:$(RESET)"
	$(Q)kubectl top nodes
	$(Q)echo ""
	$(Q)echo "$(BOLD)Pods ($(K8S_NAMESPACE)):$(RESET)"
	$(Q)kubectl top pods -n $(K8S_NAMESPACE)

## watch-hpa: Observa HPA em tempo real
watch-hpa:
	$(call log,$(BOLD)Observando HPA (CTRL+C para parar)$(RESET))
	$(Q)watch -n 2 "kubectl get hpa -n $(K8S_NAMESPACE)"

## watch-pods: Observa pods em tempo real
watch-pods:
	$(call log,$(BOLD)Observando Pods (CTRL+C para parar)$(RESET))
	$(Q)watch -n 2 "kubectl get pods -n $(K8S_NAMESPACE) -o wide"

## events: Lista eventos do cluster
events:
	$(call log,$(BOLD)Eventos Recentes$(RESET))
	$(Q)kubectl get events -n $(K8S_NAMESPACE) \
		--sort-by='.lastTimestamp' \
		--field-selector type!=Normal

## debug-shell: Shell interativo em pod (interativo)
debug-shell:
	$(Q)bash $(K8S_SCRIPTS)/exec-pod.sh $(K8S_NAMESPACE)

# ============================================================================
# BOOTSTRAP E WORKFLOWS COMPLETOS
# ============================================================================

.PHONY: bootstrap setup lab-aula-01 lab-aula-02 demo status clean clean-all reset

## bootstrap: Setup completo do zero
bootstrap: check-prereqs
	$(call log,$(BOLD)========================================$(RESET))
	$(call log,$(BOLD)  BOOTSTRAP DO AMBIENTE COMPLETO$(RESET))
	$(call log,$(BOLD)========================================$(RESET))
	$(Q)echo ""
	$(Q)$(MAKE) cluster-create VERBOSE=$(VERBOSE)
	$(Q)$(MAKE) metrics-install VERBOSE=$(VERBOSE)
	$(Q)$(MAKE) deploy VERBOSE=$(VERBOSE)
	$(Q)$(MAKE) port-forward VERBOSE=$(VERBOSE)
	$(Q)echo ""
	$(call log,$(BOLD)========================================$(RESET))
	$(call log,$(GREEN)✅ AMBIENTE PRONTO! ✅$(RESET))
	$(call log,$(BOLD)========================================$(RESET))
	$(Q)echo ""
	$(call log,$(BOLD)Próximos passos:$(RESET))
	$(call log,  1. Testar API: curl $(BASE_URL)/usuarios)
	$(call log,  2. Testes de carga: make test-load)
	$(call log,  3. Ver status: make status)
	$(Q)echo ""
	$(call log,$(YELLOW)Documentação: docs/aulas/PLANO-GERAL.md$(RESET))

## setup: Alias para bootstrap
setup: bootstrap

## lab-aula-01: Workflow completo Aula 01 (Testes de Carga)
lab-aula-01: bootstrap
	$(call log,$(BOLD)========================================$(RESET))
	$(call log,$(BOLD)  AULA 01: TESTES DE CARGA$(RESET))
	$(call log,$(BOLD)========================================$(RESET))
	$(Q)echo ""
	$(Q)$(MAKE) test-load VERBOSE=$(VERBOSE)
	$(Q)echo ""
	$(call log,$(BOLD)========================================$(RESET))
	$(call log,$(GREEN)✅ LAB AULA 01 CONCLUÍDO! ✅$(RESET))
	$(call log,$(BOLD)========================================$(RESET))
	$(Q)echo ""
	$(call log,$(BOLD)Exercícios práticos:$(RESET))
	$(call log,  1. Em outro terminal: make watch-hpa)
	$(call log,  2. Execute: make test-stress)
	$(call log,  3. Observe HPA escalar os pods)
	$(Q)echo ""

## lab-aula-02: Workflow completo Aula 02 (Segurança)
lab-aula-02: bootstrap
	$(call log,$(BOLD)========================================$(RESET))
	$(call log,$(BOLD)  AULA 02: TESTES DE SEGURANÇA$(RESET))
	$(call log,$(BOLD)========================================$(RESET))
	$(Q)echo ""
	$(Q)$(MAKE) test-security VERBOSE=$(VERBOSE)
	$(Q)echo ""
	$(call log,$(BOLD)========================================$(RESET))
	$(call log,$(GREEN)✅ LAB AULA 02 CONCLUÍDO! ✅$(RESET))
	$(call log,$(BOLD)========================================$(RESET))
	$(Q)echo ""
	$(call log,$(BOLD)Relatórios gerados em:$(RESET))
	$(call log,  security/reports/)
	$(Q)echo ""

## demo: Demonstração rápida (5 min)
demo:
	$(call log,$(BOLD)========================================$(RESET))
	$(call log,$(BOLD)  DEMO RÁPIDA (~5 MINUTOS)$(RESET))
	$(call log,$(BOLD)========================================$(RESET))
	$(Q)$(MAKE) bootstrap VERBOSE=0
	$(Q)sleep 3
	$(Q)$(MAKE) test-health VERBOSE=0
	$(Q)$(MAKE) test-smoke VERBOSE=0
	$(Q)echo ""
	$(call log,$(GREEN)✅ Demo concluída!$(RESET))
	$(Q)$(MAKE) status

## status: Status completo do ambiente
status:
	$(call log,$(BOLD)========================================$(RESET))
	$(call log,$(BOLD)  STATUS GERAL DO AMBIENTE$(RESET))
	$(call log,$(BOLD)========================================$(RESET))
	$(Q)echo ""
	$(call log,$(BOLD)Sistema Operacional:$(RESET) $(OS) $(if $(filter true,$(IS_WSL)),(WSL2)))
	$(Q)echo ""
	$(Q)if [ -f $(CLUSTER_CREATED_FLAG) ]; then \
		$(MAKE) cluster-info VERBOSE=0; \
	else \
		echo "$(RED)❌ Cluster não criado$(RESET)"; \
	fi
	$(Q)echo ""
	$(Q)if [ -f $(DEPLOY_FLAG) ]; then \
		$(MAKE) deploy-check VERBOSE=0; \
	else \
		echo "$(RED)❌ Aplicação não deployada$(RESET)"; \
	fi
	$(Q)echo ""
	$(call log,$(BOLD)Port-forward:$(RESET))
	$(Q)bash $(K8S_SCRIPTS)/port-forward-manager.sh status $(PORT_FORWARD_PID_FILE) || true

## clean: Limpeza básica (mantém cluster)
clean: port-forward-stop undeploy
	$(call log,$(GREEN)✅ Limpeza básica concluída$(RESET))

## clean-all: Limpeza completa
clean-all: port-forward-stop
	$(Q)if [ -f $(DEPLOY_FLAG) ]; then $(MAKE) undeploy VERBOSE=0; fi
	$(Q)if [ -f $(CLUSTER_CREATED_FLAG) ]; then $(MAKE) cluster-delete VERBOSE=0; fi
	$(Q)rm -rf $(STATE_DIR)
	$(call log,$(GREEN)✅ Limpeza completa!$(RESET))
	$(Q)echo ""
	$(call log,$(YELLOW)Para recriar: make bootstrap$(RESET))

## reset: Limpeza + bootstrap
reset: clean-all bootstrap
	$(call log,$(GREEN)✅ Ambiente resetado!$(RESET))

# ============================================================================
# COMANDOS ORIGINAIS SERVEREST (COMPATIBILIDADE)
# ============================================================================

.PHONY: build run stop run-dev run-debug test-contract test test-unit test-integration test-e2e-localhost

## build: Build imagem Docker ServeRest
build:
	$(Q)DOCKER_BUILDKIT=1 docker build --file Dockerfile --tag $(NAME_IMAGE) .

## run: Executa ServeRest via Docker
run:
	$(Q)docker run -p 3000:3000 $(NAME_IMAGE)

## stop: Para containers Docker
stop:
	$(Q)docker stop $$(docker ps -q) 2>/dev/null || true

## run-dev: Modo desenvolvimento
run-dev:
	$(Q)docker compose up --abort-on-container-exit --build run-dev

## run-debug: Modo debug
run-debug:
	$(Q)docker build --file Dockerfile --tag serverest-debug .
	$(Q)docker run --entrypoint "npm" -p 3000:3000 -p 9229:9229 \
		-v $(shell pwd):/app serverest-debug run start:debug

## test-contract: Testes de contrato
test-contract:
	$(Q)docker compose up --abort-on-container-exit --build test-contract

## test: Testes completos (unit + integration + e2e)
test: test-unit test-integration test-e2e-localhost

## test-unit: Testes unitários
test-unit:
	$(Q)docker compose up --abort-on-container-exit --build test-unit

## test-integration: Testes de integração
test-integration:
	$(Q)docker compose up --abort-on-container-exit --build test-integration

## test-e2e-localhost: Testes E2E
test-e2e-localhost:
	$(Q)docker compose up --abort-on-container-exit \
		--exit-code-from test-e2e-localhost --build test-e2e-localhost

# ============================================================================
# HELP SYSTEM
# ============================================================================

.PHONY: help help-full help-prereqs help-cluster help-deploy help-tests help-debug

.DEFAULT_GOAL := help

## help: Menu de ajuda principal
help:
	$(Q)echo "$(BOLD)========================================$(RESET)"
	$(Q)echo "$(BOLD)  MAKEFILE - CURSO DEVOPS QA$(RESET)"
	$(Q)echo "$(BOLD)========================================$(RESET)"
	$(Q)echo ""
	$(Q)echo "$(BOLD)COMANDOS PRINCIPAIS:$(RESET)"
	$(Q)echo "  $(GREEN)make bootstrap$(RESET)        Setup completo do ambiente"
	$(Q)echo "  $(GREEN)make lab-aula-01$(RESET)      Workflow Aula 01 (Testes de Carga)"
	$(Q)echo "  $(GREEN)make lab-aula-02$(RESET)      Workflow Aula 02 (Segurança)"
	$(Q)echo "  $(GREEN)make status$(RESET)           Status geral do ambiente"
	$(Q)echo "  $(GREEN)make clean-all$(RESET)        Limpeza completa"
	$(Q)echo ""
	$(Q)echo "$(BOLD)AJUDA POR CATEGORIA:$(RESET)"
	$(Q)echo "  $(YELLOW)make help-prereqs$(RESET)    Pré-requisitos e instalação"
	$(Q)echo "  $(YELLOW)make help-cluster$(RESET)    Cluster Kubernetes"
	$(Q)echo "  $(YELLOW)make help-deploy$(RESET)     Deploy da aplicação"
	$(Q)echo "  $(YELLOW)make help-tests$(RESET)      Testes (carga e segurança)"
	$(Q)echo "  $(YELLOW)make help-debug$(RESET)      Debug e monitoramento"
	$(Q)echo ""
	$(Q)echo "$(BOLD)CUSTOMIZAÇÃO:$(RESET)"
	$(Q)echo "  cp .env.make.example .env.make"
	$(Q)echo "  edit .env.make"
	$(Q)echo ""
	$(Q)echo "$(BOLD)MODO VERBOSE:$(RESET)"
	$(Q)echo "  make bootstrap VERBOSE=1"
	$(Q)echo ""
	$(Q)echo "Para lista completa: $(BOLD)make help-full$(RESET)"

## help-full: Lista completa de comandos
help-full:
	$(Q)echo "$(BOLD)========================================$(RESET)"
	$(Q)echo "$(BOLD)  TODOS OS COMANDOS$(RESET)"
	$(Q)echo "$(BOLD)========================================$(RESET)"
	$(Q)echo ""
	$(Q)grep -E '^## ' $(MAKEFILE_LIST) | \
		sed 's/^## //' | \
		awk 'BEGIN {FS = ": "}; {printf "  $(GREEN)%-30s$(RESET) %s\n", $$1, $$2}'

## help-prereqs: Ajuda sobre pré-requisitos
help-prereqs:
	$(Q)echo "$(BOLD)PRÉ-REQUISITOS$(RESET)"
	$(Q)echo "  make check-prereqs    Verifica ferramentas instaladas"
	$(Q)echo "  make install-guide    Guia de instalação (por SO)"
	$(Q)echo "  make install-tools    Instala ferramentas (auto)"

## help-cluster: Ajuda sobre cluster
help-cluster:
	$(Q)echo "$(BOLD)CLUSTER KUBERNETES$(RESET)"
	$(Q)echo "  make cluster-create   Cria cluster (3 nodes)"
	$(Q)echo "  make cluster-status   Status do cluster"
	$(Q)echo "  make cluster-delete   Remove cluster"
	$(Q)echo "  make cluster-logs     Exporta logs"
	$(Q)echo "  make cluster-restart  Reinicia cluster"

## help-deploy: Ajuda sobre deploy
help-deploy:
	$(Q)echo "$(BOLD)DEPLOY$(RESET)"
	$(Q)echo "  make metrics-install  Instala Metrics Server"
	$(Q)echo "  make deploy           Deploy ServeRest"
	$(Q)echo "  make deploy-check     Verifica deploy"
	$(Q)echo "  make undeploy         Remove deploy"
	$(Q)echo "  make port-forward     Port-forward (background)"
	$(Q)echo "  make port-forward-stop Para port-forward"

## help-tests: Ajuda sobre testes
help-tests:
	$(Q)echo "$(BOLD)TESTES DE CARGA$(RESET)"
	$(Q)echo "  make test-health      Health check"
	$(Q)echo "  make test-smoke       Smoke test"
	$(Q)echo "  make test-load        Testes rápidos"
	$(Q)echo "  make test-stress      Stress test"
	$(Q)echo "  make test-load-all    Todos os testes"
	$(Q)echo ""
	$(Q)echo "$(BOLD)SEGURANÇA$(RESET)"
	$(Q)echo "  make test-security    Todos os scans"
	$(Q)echo "  make test-trivy       Trivy (imagem + K8s)"
	$(Q)echo "  make test-zap         OWASP ZAP"

## help-debug: Ajuda sobre debug
help-debug:
	$(Q)echo "$(BOLD)DEBUG$(RESET)"
	$(Q)echo "  make logs             Logs dos pods"
	$(Q)echo "  make logs-follow      Logs (tempo real)"
	$(Q)echo "  make top              Uso CPU/memória"
	$(Q)echo "  make watch-hpa        Observa HPA"
	$(Q)echo "  make watch-pods       Observa pods"
	$(Q)echo "  make events           Eventos do cluster"
	$(Q)echo "  make debug-shell      Shell em pod"

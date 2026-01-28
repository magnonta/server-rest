#!/bin/bash
# ============================================================================
# VERIFICAÇÃO DE AMBIENTE
# ============================================================================
# Verifica se todas as ferramentas necessárias estão instaladas
# Compatível com: Ubuntu, WSL2, macOS
# ============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# Contador de problemas
ERRORS=0

echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD}  VERIFICAÇÃO DE PRÉ-REQUISITOS${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo ""

# Função para verificar comando
check_command() {
    local cmd=$1
    local name=$2
    local min_version=$3
    local version_flag=${4:-"--version"}
    
    echo -n "Verificando ${name}... "
    
    if command -v "$cmd" &> /dev/null; then
        local version=$(${cmd} ${version_flag} 2>&1 | head -n 1)
        echo -e "${GREEN}✅ OK${RESET}"
        echo "  Versão: $version"
        return 0
    else
        echo -e "${RED}❌ NÃO ENCONTRADO${RESET}"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Função para verificar Docker está rodando
check_docker_running() {
    echo -n "Verificando Docker (daemon)... "
    
    if docker ps &> /dev/null; then
        echo -e "${GREEN}✅ OK (rodando)${RESET}"
        return 0
    else
        echo -e "${RED}❌ ERRO${RESET}"
        echo -e "  ${YELLOW}Docker não está rodando. Inicie o Docker Desktop.${RESET}"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Verificar todas as ferramentas
check_command "docker" "Docker"
check_docker_running
check_command "kubectl" "kubectl" "" "version --client"
check_command "kind" "kind"
check_command "k6" "k6"
check_command "node" "Node.js"
check_command "npm" "npm"

echo ""
echo -e "${BOLD}========================================${RESET}"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ TODOS OS PRÉ-REQUISITOS ATENDIDOS!${RESET}"
    echo ""
    echo -e "${BOLD}Próximo passo:${RESET} make bootstrap"
    exit 0
else
    echo -e "${RED}❌ ENCONTRADOS $ERRORS PROBLEMA(S)${RESET}"
    echo ""
    echo -e "${BOLD}Para instalar as ferramentas:${RESET}"
    echo -e "  ${YELLOW}make install-guide${RESET}  # Ver guia de instalação"
    echo -e "  ${YELLOW}make install-tools${RESET}  # Instalação automática (requer sudo)"
    exit 1
fi

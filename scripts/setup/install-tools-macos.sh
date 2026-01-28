#!/bin/bash
# ============================================================================
# INSTALAÇÃO AUTOMÁTICA - macOS
# ============================================================================
# Instala todas as ferramentas necessárias via Homebrew
# ============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD}  INSTALAÇÃO AUTOMÁTICA - macOS${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo ""

# Verificar se Homebrew está instalado
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew não encontrado. Instalando...${RESET}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo -e "${GREEN}✅ Homebrew já instalado${RESET}"
fi

echo ""
echo -e "${BOLD}Atualizando Homebrew...${RESET}"
brew update

echo ""
echo -e "${BOLD}Instalando ferramentas...${RESET}"

# Docker Desktop
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Instalando Docker Desktop...${RESET}"
    brew install --cask docker
    echo -e "${GREEN}✅ Docker Desktop instalado${RESET}"
    echo -e "${YELLOW}⚠️  Inicie o Docker Desktop manualmente: open -a Docker${RESET}"
else
    echo -e "${GREEN}✅ Docker já instalado${RESET}"
fi

# kind
if ! command -v kind &> /dev/null; then
    echo -e "${YELLOW}Instalando kind...${RESET}"
    brew install kind
    echo -e "${GREEN}✅ kind instalado${RESET}"
else
    echo -e "${GREEN}✅ kind já instalado${RESET}"
fi

# kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}Instalando kubectl...${RESET}"
    brew install kubectl
    echo -e "${GREEN}✅ kubectl instalado${RESET}"
else
    echo -e "${GREEN}✅ kubectl já instalado${RESET}"
fi

# k6
if ! command -v k6 &> /dev/null; then
    echo -e "${YELLOW}Instalando k6...${RESET}"
    brew install k6
    echo -e "${GREEN}✅ k6 instalado${RESET}"
else
    echo -e "${GREEN}✅ k6 já instalado${RESET}"
fi

# Node.js
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Instalando Node.js...${RESET}"
    brew install node
    echo -e "${GREEN}✅ Node.js instalado${RESET}"
else
    echo -e "${GREEN}✅ Node.js já instalado${RESET}"
fi

echo ""
echo -e "${BOLD}========================================${RESET}"
echo -e "${GREEN}✅ INSTALAÇÃO CONCLUÍDA!${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo ""
echo -e "${YELLOW}Próximos passos:${RESET}"
echo "  1. Inicie o Docker Desktop: open -a Docker"
echo "  2. Verifique a instalação: make check-prereqs"
echo ""

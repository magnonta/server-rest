#!/bin/bash
# ============================================================================
# INSTALAÇÃO AUTOMÁTICA - Linux (Ubuntu/Debian)
# ============================================================================
# Instala todas as ferramentas necessárias
# Requer: sudo
# ============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

# Detectar arquitetura do sistema
detect_arch() {
    local machine=$(uname -m)
    case "$machine" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        arm64)   echo "arm64" ;;
        *)       echo "amd64" ;;  # fallback
    esac
}

ARCH=$(detect_arch)

echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD}  INSTALAÇÃO AUTOMÁTICA - Linux${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo ""

# Verificar sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}Este script requer sudo. Executando com sudo...${RESET}"
    sudo "$0" "$@"
    exit $?
fi

# Atualizar repositórios
echo -e "${BOLD}Atualizando repositórios...${RESET}"
apt-get update -qq

# Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Instalando Docker...${RESET}"
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
    
    # Adicionar usuário ao grupo docker
    if [ ! -z "$SUDO_USER" ]; then
        usermod -aG docker $SUDO_USER
        echo -e "${GREEN}✅ Docker instalado${RESET}"
        echo -e "${YELLOW}⚠️  Você precisa reiniciar o terminal ou executar: newgrp docker${RESET}"
    fi
else
    echo -e "${GREEN}✅ Docker já instalado${RESET}"
fi

# kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}Instalando kubectl...${RESET}"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo -e "${GREEN}✅ kubectl instalado${RESET}"
else
    echo -e "${GREEN}✅ kubectl já instalado${RESET}"
fi

# kind
if ! command -v kind &> /dev/null; then
    echo -e "${YELLOW}Instalando kind...${RESET}"
    curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-${ARCH}"
    if [ ! -s ./kind ]; then
        echo -e "${RED}❌ Falha no download do kind${RESET}"
        exit 1
    fi
    chmod +x ./kind
    mv ./kind /usr/local/bin/kind
    echo -e "${GREEN}✅ kind instalado${RESET}"
else
    echo -e "${GREEN}✅ kind já instalado${RESET}"
fi

# k6
if ! command -v k6 &> /dev/null; then
    echo -e "${YELLOW}Instalando k6...${RESET}"
    apt-get install -y gnupg2 software-properties-common
    gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
    echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | tee /etc/apt/sources.list.d/k6.list
    apt-get update -qq
    apt-get install -y k6
    echo -e "${GREEN}✅ k6 instalado${RESET}"
else
    echo -e "${GREEN}✅ k6 já instalado${RESET}"
fi

# Node.js
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Instalando Node.js...${RESET}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
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
echo "  1. REINICIE o terminal ou execute: newgrp docker"
echo "  2. Verifique a instalação: make check-prereqs"
echo ""

#!/bin/bash
# ============================================================================
# GUIA DE INSTALAÇÃO
# ============================================================================
# Mostra guia de instalação personalizado por plataforma
# Uso: show-install-guide.sh <OS> <IS_WSL>
# ============================================================================

OS=${1:-$(uname -s)}
IS_WSL=${2:-false}

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD}  GUIA DE INSTALAÇÃO DE FERRAMENTAS${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo ""

if [ "$IS_WSL" = "true" ]; then
    echo -e "${BLUE}Sistema Detectado:${RESET} ${YELLOW}WSL2 (Windows Subsystem for Linux)${RESET}"
    echo ""
    echo -e "${GREEN}Use os comandos Linux abaixo:${RESET}"
    echo ""
    OS="Linux"
fi

if [ "$OS" = "Darwin" ]; then
    echo -e "${GREEN}macOS - Use Homebrew:${RESET}"
    echo ""
    echo "# 1. Instalar Homebrew (se ainda não tiver):"
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    echo ""
    echo "# 2. Instalar ferramentas:"
    echo "brew install docker kind kubectl k6 node"
    echo ""
    echo "# 3. Instalar Docker Desktop:"
    echo "brew install --cask docker"
    echo ""
    echo "# 4. Iniciar Docker Desktop:"
    echo "open -a Docker"
    echo ""
    echo -e "${YELLOW}Ou execute automaticamente:${RESET} make install-tools"
    
elif [ "$OS" = "Linux" ]; then
    echo -e "${GREEN}Linux (Ubuntu/Debian):${RESET}"
    echo ""
    echo "# 1. Atualizar repositórios:"
    echo "sudo apt-get update"
    echo ""
    echo "# 2. Instalar Docker:"
    echo "sudo apt-get install -y docker.io"
    echo "sudo systemctl start docker"
    echo "sudo systemctl enable docker"
    echo "sudo usermod -aG docker \$USER"
    echo ""
    echo "# 3. Instalar kubectl:"
    echo "curl -LO \"https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\""
    echo "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"
    echo ""
    echo "# 4. Instalar kind:"
    echo "curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64"
    echo "chmod +x ./kind"
    echo "sudo mv ./kind /usr/local/bin/kind"
    echo ""
    echo "# 5. Instalar k6:"
    echo "sudo gpg -k"
    echo "sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69"
    echo "echo \"deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main\" | sudo tee /etc/apt/sources.list.d/k6.list"
    echo "sudo apt-get update"
    echo "sudo apt-get install k6"
    echo ""
    echo "# 6. Instalar Node.js:"
    echo "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
    echo "sudo apt-get install -y nodejs"
    echo ""
    echo -e "${YELLOW}Ou execute automaticamente:${RESET} make install-tools"
    echo -e "${RED}Após instalação, REINICIE o terminal ou execute:${RESET} newgrp docker"
    
else
    echo -e "${YELLOW}Windows - Use PowerShell como Administrador:${RESET}"
    echo ""
    echo "# Opção 1: Script automatizado (recomendado)"
    echo ".\\scripts\\setup\\install-tools-windows.ps1"
    echo ""
    echo "# Opção 2: Instalação manual com Chocolatey"
    echo "# 1. Instalar Chocolatey:"
    echo "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    echo ""
    echo "# 2. Instalar ferramentas:"
    echo "choco install docker-desktop kind kubernetes-cli k6 nodejs -y"
    echo ""
    echo "# 3. Habilitar WSL2 (recomendado para melhor compatibilidade):"
    echo "wsl --install"
    echo ""
    echo -e "${BLUE}Após instalar WSL2, recomendamos trabalhar dentro do WSL2:${RESET}"
    echo "  1. Abra 'Ubuntu' no menu iniciar"
    echo "  2. Execute os comandos Linux acima"
    echo "  3. Use 'make' dentro do WSL2"
fi

echo ""
echo -e "${BOLD}Após instalação, verifique com:${RESET}"
echo "  make check-prereqs"
echo ""

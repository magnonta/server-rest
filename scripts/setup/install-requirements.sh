#!/bin/bash
# ============================================================================
# INSTALAÇÃO AUTOMÁTICA INTELIGENTE
# ============================================================================
# Detecta o sistema operacional e instala todas as dependências necessárias
# Suporta: macOS, Linux (Ubuntu/Debian), WSL2
# ============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# ============================================================================
# FUNÇÕES DE DETECÇÃO
# ============================================================================

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi microsoft /proc/version 2>/dev/null; then
            echo "wsl2"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

detect_arch() {
    local machine=$(uname -m)
    case "$machine" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        arm64)   echo "arm64" ;;
        *)       echo "amd64" ;;  # fallback
    esac
}

# ============================================================================
# VERIFICAÇÃO DE FERRAMENTAS
# ============================================================================

check_tool() {
    local tool=$1
    if command -v "$tool" &> /dev/null; then
        echo -e "${GREEN}✅ $tool já instalado${RESET}"
        return 0
    else
        echo -e "${YELLOW}⏳ $tool será instalado${RESET}"
        return 1
    fi
}

# ============================================================================
# INSTALADORES POR SISTEMA
# ============================================================================

install_macos() {
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║  INSTALAÇÃO AUTOMÁTICA - macOS        ║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════╝${RESET}"
    echo ""
    
    # Verificar/Instalar Homebrew
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}📦 Instalando Homebrew...${RESET}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo -e "${GREEN}✅ Homebrew instalado${RESET}"
    else
        echo -e "${GREEN}✅ Homebrew já instalado${RESET}"
        echo -e "${BLUE}🔄 Atualizando Homebrew...${RESET}"
        brew update > /dev/null 2>&1
    fi
    
    echo ""
    echo -e "${BOLD}Instalando ferramentas via Homebrew...${RESET}"
    echo ""
    
    # Docker Desktop
    if ! check_tool docker; then
        echo -e "${YELLOW}📦 Instalando Docker Desktop...${RESET}"
        brew install --cask docker
        echo -e "${GREEN}✅ Docker Desktop instalado${RESET}"
        echo -e "${YELLOW}⚠️  IMPORTANTE: Inicie o Docker Desktop: open -a Docker${RESET}"
    fi
    
    # kubectl
    if ! check_tool kubectl; then
        echo -e "${YELLOW}📦 Instalando kubectl...${RESET}"
        brew install kubectl
        echo -e "${GREEN}✅ kubectl instalado${RESET}"
    fi
    
    # kind
    if ! check_tool kind; then
        echo -e "${YELLOW}📦 Instalando kind...${RESET}"
        brew install kind
        echo -e "${GREEN}✅ kind instalado${RESET}"
    fi
    
    # k6
    if ! check_tool k6; then
        echo -e "${YELLOW}📦 Instalando k6...${RESET}"
        brew install k6
        echo -e "${GREEN}✅ k6 instalado${RESET}"
    fi
    
    # Node.js
    if ! check_tool node; then
        echo -e "${YELLOW}📦 Instalando Node.js...${RESET}"
        brew install node
        echo -e "${GREEN}✅ Node.js instalado${RESET}"
    fi
    
    
    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║  ✅ INSTALAÇÃO CONCLUÍDA - macOS       ║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${YELLOW}📋 Próximos passos:${RESET}"
    echo "  1️⃣  Inicie o Docker Desktop: ${BOLD}open -a Docker${RESET}"
    echo "  2️⃣  Verifique a instalação: ${BOLD}make check-prereqs${RESET}"
    echo "  3️⃣  Crie o ambiente: ${BOLD}make bootstrap${RESET}"
    echo ""
}

install_linux() {
    local distro=$1
    
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║  INSTALAÇÃO AUTOMÁTICA - Linux        ║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${BLUE}Distribuição detectada: ${distro}${RESET}"
    echo ""
    
    # Verificar sudo
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}⚠️  Este script requer privilégios sudo${RESET}"
        echo -e "${BLUE}🔄 Executando com sudo...${RESET}"
        exec sudo "$0" "$@"
    fi
    
    case "$distro" in
        ubuntu|debian|pop)
            install_debian_based
            ;;
        fedora|rhel|centos)
            install_redhat_based
            ;;
        arch|manjaro)
            install_arch_based
            ;;
        *)
            echo -e "${YELLOW}⚠️  Distribuição não reconhecida: $distro${RESET}"
            echo -e "${YELLOW}Tentando instalação genérica...${RESET}"
            install_debian_based
            ;;
    esac
}

install_debian_based() {
    echo -e "${BLUE}🔄 Atualizando repositórios apt...${RESET}"
    apt-get update -qq
    
    # Ferramentas básicas
    echo -e "${BLUE}📦 Instalando ferramentas básicas...${RESET}"
    apt-get install -y -qq curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release
    
    # Docker
    if ! check_tool docker; then
        echo -e "${YELLOW}📦 Instalando Docker...${RESET}"
        
        # Remover versões antigas
        apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
        
        # Adicionar repositório oficial Docker
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        apt-get update -qq
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        # Iniciar e habilitar Docker
        systemctl start docker
        systemctl enable docker
        
        # Adicionar usuário ao grupo docker
        if [ ! -z "$SUDO_USER" ]; then
            usermod -aG docker "$SUDO_USER"
            echo -e "${GREEN}✅ Docker instalado${RESET}"
            echo -e "${YELLOW}⚠️  Execute 'newgrp docker' ou reinicie o terminal${RESET}"
        fi
    fi
    # kubectl
    if ! check_tool kubectl; then
        echo -e "${YELLOW}📦 Instalando kubectl...${RESET}"
        local arch=$(detect_arch)
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${arch}/kubectl"
        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
        echo -e "${GREEN}✅ kubectl instalado${RESET}"
    fi

    
    # kind
    if ! check_tool kind; then
        echo -e "${YELLOW}📦 Instalando kind...${RESET}"
        local arch=$(detect_arch)
        curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-${arch}"
        if [ ! -s ./kind ]; then
            echo -e "${RED}❌ Falha no download do kind${RESET}"
            return 1
        fi
        chmod +x ./kind
        mv ./kind /usr/local/bin/kind
        echo -e "${GREEN}✅ kind instalado${RESET}"
    fi
    
    # k6
    if ! check_tool k6; then
        echo -e "${YELLOW}📦 Instalando k6...${RESET}"
        gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69 2>/dev/null
        echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | tee /etc/apt/sources.list.d/k6.list
        apt-get update -qq
        apt-get install -y k6
        echo -e "${GREEN}✅ k6 instalado${RESET}"
    fi
    
    # Node.js
    if ! check_tool node; then
        echo -e "${YELLOW}📦 Instalando Node.js...${RESET}"
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
        echo -e "${GREEN}✅ Node.js instalado${RESET}"
    fi
    
    
    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║  ✅ INSTALAÇÃO CONCLUÍDA - Linux       ║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${YELLOW}📋 Próximos passos:${RESET}"
    echo "  1️⃣  REINICIE o terminal ou execute: ${BOLD}newgrp docker${RESET}"
    echo "  2️⃣  Verifique a instalação: ${BOLD}make check-prereqs${RESET}"
    echo "  3️⃣  Crie o ambiente: ${BOLD}make bootstrap${RESET}"
    echo ""
}

install_redhat_based() {
    echo -e "${BLUE}🔄 Atualizando repositórios dnf/yum...${RESET}"
    dnf update -y -q 2>/dev/null || yum update -y -q
    
    # Docker
    if ! check_tool docker; then
        echo -e "${YELLOW}📦 Instalando Docker...${RESET}"
        dnf install -y docker 2>/dev/null || yum install -y docker
        systemctl start docker
        systemctl enable docker
        usermod -aG docker "$SUDO_USER" 2>/dev/null || true
        echo -e "${GREEN}✅ Docker instalado${RESET}"
    fi
    
    # kubectl, kind, k6, node - instalação manual
    install_common_tools_manual
    
    echo -e "${BOLD}${GREEN}✅ Instalação concluída!${RESET}"
}

install_arch_based() {
    echo -e "${BLUE}🔄 Atualizando repositórios pacman...${RESET}"
    pacman -Syu --noconfirm
    
    # Docker
    if ! check_tool docker; then
        echo -e "${YELLOW}📦 Instalando Docker...${RESET}"
        pacman -S --noconfirm docker
        systemctl start docker
        systemctl enable docker
        usermod -aG docker "$SUDO_USER" 2>/dev/null || true
        echo -e "${GREEN}✅ Docker instalado${RESET}"
    fi
    
    # kubectl
    if ! check_tool kubectl; then
        pacman -S --noconfirm kubectl
    fi
    
    # kind, k6, node
    install_common_tools_manual
    
    echo -e "${BOLD}${GREEN}✅ Instalação concluída!${RESET}"
}

install_common_tools_manual() {
    # kubectl
    if ! check_tool kubectl; then
        echo -e "${YELLOW}📦 Instalando kubectl...${RESET}"
        local arch=$(detect_arch)
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${arch}/kubectl"
        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
        echo -e "${GREEN}✅ kubectl instalado${RESET}"
    fi
    
    # kind
    if ! check_tool kind; then
        echo -e "${YELLOW}📦 Instalando kind...${RESET}"
        local arch=$(detect_arch)
        curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-${arch}"
        if [ ! -s ./kind ]; then
            echo -e "${RED}❌ Falha no download do kind${RESET}"
            return 1
        fi
        chmod +x ./kind
        mv ./kind /usr/local/bin/kind
        echo -e "${GREEN}✅ kind instalado${RESET}"
    fi
    
    # k6
    if ! check_tool k6; then
        echo -e "${YELLOW}📦 Instalando k6...${RESET}"
        local arch=$(detect_arch)
        local k6_version="v1.6.1"
        curl -Lo k6.tar.gz "https://github.com/grafana/k6/releases/download/${k6_version}/k6-${k6_version}-linux-${arch}.tar.gz"
        tar -xzf k6.tar.gz
        mv k6-${k6_version}-linux-${arch}/k6 /usr/local/bin/
        rm -rf k6.tar.gz k6-${k6_version}-linux-${arch}
        echo -e "${GREEN}✅ k6 instalado${RESET}"
    fi
    
    # Node.js
    if ! check_tool node; then
        echo -e "${YELLOW}📦 Instalando Node.js...${RESET}"
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        echo -e "${GREEN}✅ Node.js instalado${RESET}"
    fi
}

install_wsl2() {
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║  INSTALAÇÃO AUTOMÁTICA - WSL2         ║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${YELLOW}💡 WSL2 detectado - usando instalação Linux${RESET}"
    echo ""
    
    # WSL2 usa instalação Linux
    local distro=$(detect_distro)
    install_linux "$distro"
    
    echo -e "${YELLOW}⚠️  ATENÇÃO WSL2:${RESET}"
    echo "  • Docker Desktop deve estar rodando no Windows"
    echo "  • Ou use Docker Engine diretamente no WSL2"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    clear
    
    echo -e "${BOLD}${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║        INSTALADOR AUTOMÁTICO - CURSO DEVOPS QA            ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo ""
    
    # Detectar sistema operacional
    local os_type=$(detect_os)
    echo -e "${BLUE}🔍 Detectando sistema operacional...${RESET}"
    echo -e "${GREEN}Sistema: ${BOLD}$os_type${RESET}"
    echo ""
    
    # Confirmar instalação
    echo -e "${YELLOW}⚠️  Este script irá instalar:${RESET}"
    echo "  • Docker"
    echo "  • kubectl"
    echo "  • kind"
    echo "  • k6"
    echo "  • Node.js"
    echo ""
    
    read -p "Continuar com a instalação? [s/N] " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
        echo -e "${RED}❌ Instalação cancelada${RESET}"
        exit 1
    fi
    
    echo ""
    
    # Executar instalação baseada no OS
    case "$os_type" in
        macos)
            install_macos
            ;;
        linux)
            local distro=$(detect_distro)
            install_linux "$distro"
            ;;
        wsl2)
            install_wsl2
            ;;
        *)
            echo -e "${RED}❌ Sistema operacional não suportado: $os_type${RESET}"
            echo -e "${YELLOW}Sistemas suportados: macOS, Linux, WSL2${RESET}"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${BOLD}${GREEN}🎉 Instalação finalizada!${RESET}"
    echo ""
}

# Executar
main "$@"

# 🛠️ Guia de Instalação - Curso DevOps QA

## 🚀 Instalação Automática (Recomendado)

### Opção 1: Instalação Completa em 1 Comando

```bash
make install-tools
```

**O que esse comando faz:**
- ✅ Detecta automaticamente seu sistema operacional
- ✅ Identifica distribuição Linux (se aplicável)
- ✅ Instala todas as ferramentas necessárias
- ✅ Configura permissões e grupos corretos
- ✅ Fornece instruções pós-instalação

**Sistemas suportados:**
- macOS (via Homebrew)
- Ubuntu/Debian (via apt)
- Fedora/RHEL/CentOS (via dnf/yum)
- Arch Linux (via pacman)
- WSL2 (Windows Subsystem for Linux)

---

### Opção 2: Verificação + Instalação Interativa

```bash
make setup-environment
```

**O que esse comando faz:**
1. Verifica quais ferramentas já estão instaladas
2. Lista o que está faltando
3. Oferece instalação automática (com confirmação)
4. Ou mostra alternativas (guia manual, comandos específicos)

---

## 🔍 Verificar Instalação

```bash
make check-prereqs
```

**Saída esperada:**
```
========================================
  VERIFICAÇÃO DE PRÉ-REQUISITOS
========================================

Verificando Docker... ✅ OK
  Versão: Docker version 27.5.1
Verificando Docker (daemon)... ✅ OK (rodando)
Verificando kubectl... ✅ OK
  Versão: Client Version: v1.31.0
Verificando kind... ✅ OK
  Versão: kind version 0.31.0
Verificando k6... ✅ OK
  Versão: k6 v1.5.0
Verificando Node.js... ✅ OK
  Versão: v25.2.1
Verificando npm... ✅ OK
  Versão: 11.6.2

========================================
✅ TODOS OS PRÉ-REQUISITOS ATENDIDOS!
```

---

## 📖 Instalação Manual

### Ver Guia para Seu Sistema

```bash
make install-guide
```

Este comando mostra instruções específicas para:
- macOS
- Ubuntu/Debian
- Fedora/RHEL
- Arch Linux
- WSL2
- Windows (com PowerShell)

---

## 🔧 Ferramentas Necessárias

| Ferramenta | Versão Mínima | Para que serve |
|------------|---------------|----------------|
| **Docker** | 20.10+ | Runtime de containers |
| **kubectl** | 1.28+ | CLI do Kubernetes |
| **kind** | 0.20+ | Kubernetes local (kind = Kubernetes in Docker) |
| **k6** | 0.45+ | Testes de carga |
| **Node.js** | 18+ | Runtime da aplicação |
| **npm** | 9+ | Gerenciador de pacotes Node |
| **Trivy** | 0.45+ | Scan de segurança (opcional) |

---

## 💻 Instalação por Sistema Operacional

### macOS

```bash
# Automática
make install-tools

# Ou manualmente via Homebrew
brew install docker kubectl kind k6 node
brew install --cask docker
```

**Pós-instalação:**
1. Abra o Docker Desktop: `open -a Docker`
2. Verifique: `make check-prereqs`

---

### Ubuntu/Debian

```bash
# Automática (requer sudo)
make install-tools

# Ou manualmente
sudo apt update
sudo apt install -y docker.io kubectl
# ... (ver make install-guide para comandos completos)
```

**Pós-instalação:**
1. Adicione seu usuário ao grupo docker: `sudo usermod -aG docker $USER`
2. Reinicie o terminal ou execute: `newgrp docker`
3. Verifique: `make check-prereqs`

---

### Fedora/RHEL/CentOS

```bash
# Automática (requer sudo)
make install-tools

# Ou manualmente
sudo dnf install -y docker kubectl
# ... (ver make install-guide para comandos completos)
```

---

### Arch Linux

```bash
# Automática (requer sudo)
make install-tools

# Ou manualmente
sudo pacman -S docker kubectl
# ... (ver make install-guide para comandos completos)
```

---

### WSL2 (Windows)

```bash
# Dentro do WSL2 Ubuntu/Debian
make install-tools

# Ou use Docker Desktop for Windows + ferramentas no WSL2
```

**Nota:** Se usar Docker Desktop no Windows, ele integra com WSL2 automaticamente.

---

## 🚨 Problemas Comuns na Instalação

### Docker não inicia (Linux)

```bash
# Iniciar Docker
sudo systemctl start docker

# Habilitar no boot
sudo systemctl enable docker

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker
```

---

### Homebrew não encontrado (macOS)

```bash
# Instalar Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Depois execute
make install-tools
```

---

### Erro de permissão (Linux)

```bash
# Algumas instalações requerem sudo
sudo make install-tools

# Ou execute o script diretamente
sudo bash scripts/setup/install-requirements.sh
```

---

### kind/k6 não encontrado após instalação

```bash
# Verifique se /usr/local/bin está no PATH
echo $PATH

# Adicione ao PATH se necessário (Linux/macOS)
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## 🔄 Reinstalação / Atualização

### Atualizar todas as ferramentas (macOS)

```bash
brew update
brew upgrade docker kubectl kind k6 node
```

---

### Atualizar todas as ferramentas (Ubuntu/Debian)

```bash
sudo apt update
sudo apt upgrade -y docker.io kubectl k6
```

---

## ✅ Validação Pós-Instalação

Após instalar tudo, execute esta sequência para validar:

```bash
# 1. Verificar ferramentas
make check-prereqs

# 2. Criar ambiente de teste
make bootstrap

# 3. Verificar que tudo funciona
make status

# 4. Testar API
curl http://localhost:30000/usuarios

# 5. Limpar (opcional)
make clean-all
```

Se todos os comandos funcionarem, a instalação está **100% OK**! 🎉

---

## 📞 Suporte

### Verificar logs de instalação

O script de instalação mostra logs detalhados. Se algo falhar:

1. Execute com verbose: `make install-tools VERBOSE=1`
2. Veja o erro específico
3. Consulte este guia
4. Execute comandos individuais manualmente

---

### Instalação de ferramenta específica

Se apenas uma ferramenta estiver faltando, instale-a manualmente:

```bash
# Docker (Ubuntu)
sudo apt install -y docker.io

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# k6 (Ubuntu)
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt update
sudo apt install -y k6

# Node.js (Ubuntu)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

---

## 🎯 Quick Start Após Instalação

```bash
# 1. Clone (se ainda não fez)
git clone https://github.com/magnonta/server-rest.git
cd server-rest

# 2. Verifique
make check-prereqs

# 3. Configure (opcional)
cp .env.make.example .env.make
# edite .env.make se necessário

# 4. Crie ambiente
make bootstrap

# 5. Execute labs
make lab-aula-01    # Testes de carga
make lab-aula-02    # Testes de segurança
```

---

**Versão:** 1.0  
**Última Atualização:** Janeiro 2025  
**Curso:** DevOps QA - Pós-Graduação UNIESP

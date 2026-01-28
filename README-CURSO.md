# 🎓 ServeRest - Curso DevOps QA

> **Repositório educacional para o Curso de DevOps QA - Pós-Graduação UNIESP**  
> Testes de Carga e Segurança em CI/CD com Kubernetes

---

## 🚀 Como Usar Este Repositório - 3 Passos Simples

### 1️⃣ Clone e Verifique

```bash
# Clone o repositório
git clone https://github.com/magnonta/server-rest.git
cd server-rest

# Verifique se tem todas as ferramentas instaladas
make check-prereqs
```

**Se faltar alguma ferramenta**, veja o [Guia de Instalação](#️-instalação-de-ferramentas).

---

### 2️⃣ Crie o Ambiente

```bash
# Um único comando cria tudo automaticamente
make bootstrap
```

**O que esse comando faz?**
- ✅ Cria cluster Kubernetes local (kind)
- ✅ Instala Metrics Server
- ✅ Faz deploy da aplicação ServeRest
- ✅ Configura acesso em http://localhost:30000
- ✅ Testa se está tudo funcionando

**Tempo:** 2-3 minutos ⏱️

---

### 3️⃣ Execute os Labs

```bash
# Para Aula 01 - Testes de Carga
make lab-aula-01

# Para Aula 02 - Testes de Segurança
make lab-aula-02

# Para ver o status do ambiente
make status
```

**Pronto!** 🎉 Você está rodando testes de carga e segurança em um cluster Kubernetes local!

---

## 📋 Comandos Mais Usados

### Comandos Essenciais (Use Estes!)

```bash
# COMEÇAR
make bootstrap              # Cria o ambiente completo
make status                 # Ver status de tudo

# TESTAR - CARGA
make test-health            # Teste rápido (10 requisições)
make test-load              # Teste de carga completo
make lab-aula-01            # TODOS os testes de carga

# TESTAR - SEGURANÇA
make test-trivy             # Scan de segurança
make test-zap               # Teste de vulnerabilidades web
make lab-aula-02            # TODOS os testes de segurança

# MONITORAR
make logs                   # Ver logs dos pods
make top                    # Ver uso de CPU/Memória
make watch-hpa              # Ver escalabilidade em tempo real

# LIMPAR
make clean                  # Remove deploy
make clean-all              # Remove tudo (cluster também)
make reset                  # Limpa e recria tudo
```

---

## 🎯 Workflows das Aulas

### 🧪 Aula 01: Testes de Carga

**Objetivo:** Aprender a fazer testes de carga em aplicações Kubernetes

```bash
# Workflow completo em 1 comando
make lab-aula-01
```

**O que executa:**
1. ✅ Cria ambiente (se não existir)
2. ✅ Health Check - Verifica se API está OK
3. ✅ Smoke Test - Teste leve (5 usuários)
4. ✅ Load Test - Teste médio (50 usuários)
5. ✅ Stress Test - Teste pesado (até 100 usuários)
6. ✅ Spike Test - Teste de pico súbito
7. ✅ Soak Test - Teste de duração (5 minutos)

**Tempo total:** ~15 minutos

**Comandos individuais:**
```bash
make test-health            # Apenas health check
make test-smoke             # Apenas smoke test
make test-load              # Apenas load test
make test-stress            # Apenas stress test
```

---

### 🔒 Aula 02: Testes de Segurança

**Objetivo:** Aprender a fazer testes de segurança em aplicações Kubernetes

```bash
# Workflow completo em 1 comando
make lab-aula-02
```

**O que executa:**
1. ✅ Cria ambiente (se não existir)
2. ✅ Trivy - Scan de vulnerabilidades na imagem Docker
3. ✅ Trivy - Scan de configurações Kubernetes
4. ✅ OWASP ZAP - Scan de vulnerabilidades web

**Tempo total:** ~10 minutos

**Comandos individuais:**
```bash
make test-trivy-image       # Scan da imagem Docker
make test-trivy-k8s         # Scan do Kubernetes
make test-zap               # Scan web com ZAP
```

---

## 🛠️ Instalação de Ferramentas

### Ver Guia de Instalação

```bash
make install-guide
```

Este comando mostra **instruções detalhadas** para seu sistema operacional.

---

### Instalação Automatizada

#### macOS

```bash
make install-tools
```

Instala tudo via Homebrew automaticamente.

---

#### Linux / Ubuntu / WSL2

```bash
make install-tools
```

Instala via apt e scripts oficiais.

---

#### Instalação Manual

Se preferir instalar manualmente, você precisa de:

| Ferramenta | Para que serve | Link |
|------------|----------------|------|
| **Docker** | Rodar containers | https://www.docker.com/get-started |
| **kubectl** | CLI do Kubernetes | https://kubernetes.io/docs/tasks/tools/ |
| **kind** | Kubernetes local | https://kind.sigs.k8s.io/docs/user/quick-start/ |
| **k6** | Testes de carga | https://k6.io/docs/get-started/installation/ |
| **Node.js** | Runtime da aplicação | https://nodejs.org/ |
| **npm** | Gerenciador de pacotes | Vem com Node.js |

---

## 🎬 Exemplo de Uso Completo

### Primeira Vez (Aula 01)

```bash
# 1. Clone
git clone https://github.com/magnonta/server-rest.git
cd server-rest

# 2. Verifique ferramentas
make check-prereqs
# Se faltar algo: make install-guide

# 3. Crie ambiente
make bootstrap
# Aguarde 2-3 minutos

# 4. Teste a API manualmente
curl http://localhost:30000/usuarios

# 5. Execute testes de carga
make lab-aula-01
# Aguarde ~15 minutos

# 6. Veja o resultado
make status

# 7. Ao final da aula (opcional)
make clean-all
```

---

### Segunda Aula (Aula 02)

```bash
# Se já fez a Aula 01 e limpou, recrie o ambiente
make bootstrap

# Execute todos os testes de segurança
make lab-aula-02

# Veja os relatórios
cat tmp/trivy-image-report.txt
cat tmp/trivy-k8s-report.txt

# Ao final
make clean-all
```

---

## 📊 Monitoramento Durante os Testes

### Ver Tudo Acontecendo em Tempo Real

Abra **3 terminais** e rode:

```bash
# Terminal 1 - Executar teste
make test-load

# Terminal 2 - Ver escalabilidade (HPA)
make watch-hpa

# Terminal 3 - Ver logs da aplicação
make logs-follow
```

Você verá:
- Terminal 1: Resultados do k6
- Terminal 2: Pods sendo criados/destruídos automaticamente
- Terminal 3: Logs da aplicação processando requisições

**Pressione Ctrl+C** para sair dos comandos `watch-` e `logs-follow`.

---

## 🔧 Problemas Comuns

### ❌ "Docker não está rodando"

**Solução:**
- **macOS/Windows:** Abra o Docker Desktop
- **Linux:** `sudo systemctl start docker`

---

### ❌ "Porta 30000 já está em uso"

**Solução:**
```bash
# Mata processo na porta 30000
lsof -ti:30000 | xargs kill -9

# Reinicia port-forward
make port-forward
```

---

### ❌ "Cluster já existe"

**Solução:**
```bash
# Remove cluster antigo e cria novo
make cluster-restart
```

---

### ❌ "Pods não ficam prontos"

**Solução:**
```bash
# Ver o que está acontecendo
make events

# Ver logs dos pods
make logs

# Se necessário, reinicie tudo
make reset
```

---

### ❌ "Métricas não aparecem (unknown/50%)"

**Causa:** Metrics Server ainda não coletou dados.

**Solução:**
```bash
# Aguarde 60 segundos
sleep 60
make status
```

---

### 🆘 Nada Funciona?

```bash
# Limpeza completa e recriação
make reset
```

Este comando:
1. Para tudo
2. Remove cluster
3. Limpa estado
4. Recria tudo do zero

---

## 📚 Comandos por Categoria

### 🏗️ Setup e Ambiente

```bash
make check-prereqs          # Verifica ferramentas instaladas
make install-guide          # Mostra como instalar
make install-tools          # Instala automaticamente (macOS/Linux)
make bootstrap              # Cria ambiente completo
make status                 # Status geral
make reset                  # Limpa e recria tudo
```

---

### ☸️ Cluster Kubernetes

```bash
make cluster-create         # Cria cluster kind
make cluster-delete         # Remove cluster
make cluster-status         # Info do cluster
make cluster-restart        # Reinicia cluster
```

---

### 🚀 Deploy da Aplicação

```bash
make deploy                 # Faz deploy do ServeRest
make undeploy               # Remove deploy
make deploy-check           # Verifica status
make port-forward           # Inicia acesso (localhost:30000)
```

---

### 🧪 Testes de Carga (k6)

```bash
make test-health            # Health check (10 req, 10s)
make test-smoke             # Smoke test (100 req, 5 VUs)
make test-load              # Load test (1000 req, 50 VUs)
make test-stress            # Stress test (até 100 VUs, 5min)
make test-spike             # Spike test (pico súbito, 3min)
make test-soak              # Soak test (10 VUs, 5min)
make test-load-all          # TODOS os testes em sequência
```

---

### 🔒 Testes de Segurança

```bash
make test-trivy             # Trivy completo (imagem + k8s)
make test-trivy-image       # Scan de imagem Docker
make test-trivy-k8s         # Scan de configs Kubernetes
make test-zap               # OWASP ZAP scan
make test-security          # TODOS os testes de segurança
```

---

### 👀 Monitoramento e Debug

```bash
make logs                   # Últimos logs (100 linhas)
make logs-follow            # Seguir logs em tempo real
make top                    # CPU/Memória dos pods
make watch-hpa              # Monitorar HPA em tempo real
make events                 # Eventos do cluster
make describe-pod           # Descrever pod (interativo)
make debug-shell            # Shell dentro do pod (interativo)
```

---

### 🧹 Limpeza

```bash
make clean                  # Remove deploy + para port-forward
make clean-all              # Remove tudo (cluster também)
make reset                  # clean-all + bootstrap
```

---

### ❓ Ajuda

```bash
make help                   # Comandos principais
make help-full              # Todos os comandos
make help-prereqs           # Ajuda sobre instalação
make help-cluster           # Ajuda sobre cluster
make help-deploy            # Ajuda sobre deploy
make help-tests             # Ajuda sobre testes
make help-debug             # Ajuda sobre monitoramento
```

---

## 🎨 Customização (Avançado)

### Alterar Configurações

```bash
# Copie o arquivo de exemplo
cp .env.make.example .env.make

# Edite com seu editor preferido
vim .env.make
# ou
nano .env.make
```

**Opções disponíveis:**
```bash
KIND_CLUSTER_NAME=serverest-cluster    # Nome do cluster
K8S_NAMESPACE=serverest                # Namespace Kubernetes
BASE_URL=http://localhost:30000        # URL da API
POD_READY_TIMEOUT=120                  # Timeout para pods (segundos)
METRICS_WAIT_TIME=30                   # Espera para métricas (segundos)
VERBOSE=0                              # Modo verbose (0 ou 1)
```

---

### Modo Verbose (Ver Detalhes)

```bash
# Adicione VERBOSE=1 em qualquer comando
make bootstrap VERBOSE=1
make test-load VERBOSE=1
make status VERBOSE=1
```

Mostra todos os comandos executados em detalhe.

---

## 📁 Estrutura do Repositório

```
server-rest/
├── Makefile                    # 750+ linhas de automação
├── README-CURSO.md             # Este arquivo
├── .env.make.example           # Template de configuração
│
├── k6/                         # Testes de carga
│   ├── scripts/                # 6 cenários de teste
│   │   ├── 00-health-check.js
│   │   ├── 01-smoke-test.js
│   │   ├── 02-load-test.js
│   │   ├── 03-stress-test.js
│   │   ├── 04-spike-test.js
│   │   └── 05-soak-test.js
│   └── modules/                # Módulos reutilizáveis
│
├── k8s/                        # Kubernetes
│   ├── kind/
│   │   └── kind-config.yaml    # Configuração do cluster
│   └── serverest/              # Manifests da aplicação
│       ├── 00-namespace.yaml
│       ├── 01-configmap.yaml
│       ├── 02-deployment.yaml
│       ├── 03-service.yaml
│       └── 04-hpa.yaml
│
├── scripts/                    # Scripts auxiliares
│   ├── setup/                  # Instalação e verificação
│   ├── k8s/                    # Helpers Kubernetes
│   ├── load-testing/           # Suite k6
│   └── security/               # Scans de segurança
│
├── .github/workflows/          # CI/CD pipelines
│   ├── aula-01-load-testing.yml
│   └── aula-02-security-full.yml
│
└── security/                   # Configurações de segurança
    └── trivy/
```

---

## 🎓 Informações do Curso

**Curso:** DevOps para QA - Pós-Graduação  
**Instituição:** UNIESP  
**Carga Horária:** 16 horas (2 sábados de 8h cada)  

**Módulos:**
- **Aula 01 (8h):** Testes de Carga em CI/CD
- **Aula 02 (8h):** Testes de Segurança em CI/CD

---

## 🛡️ Tecnologias Utilizadas

| Tecnologia | Versão | Uso |
|------------|--------|-----|
| **Docker** | 20.10+ | Container runtime |
| **Kubernetes (kind)** | 1.28+ | Orquestração local |
| **kubectl** | 1.28+ | CLI Kubernetes |
| **k6** | 0.45+ | Testes de carga |
| **Trivy** | 0.45+ | Scan de segurança |
| **OWASP ZAP** | 2.14+ | Testes de segurança web |
| **Node.js** | 18+ | Runtime da aplicação |
| **GitHub Actions** | - | CI/CD |

---

## 💡 Dicas para Aproveitar ao Máximo

### 1. Comece Simples
```bash
make bootstrap
make test-health
make status
```

### 2. Use os Workflows Completos
```bash
# Deixe rodar tudo automaticamente
make lab-aula-01
make lab-aula-02
```

### 3. Monitore em Tempo Real
```bash
# Terminal 1
make watch-hpa

# Terminal 2
make test-load
```

### 4. Explore os Comandos
```bash
make help-full
```

### 5. Quando Tiver Problemas
```bash
make events
make logs
make status
```

---

## 🌐 Compatibilidade

| Sistema | Status |
|---------|--------|
| macOS | ✅ Totalmente suportado |
| Linux/Ubuntu | ✅ Totalmente suportado |
| WSL2 (Windows) | ✅ Totalmente suportado |
| Windows PowerShell | ❌ Use WSL2 |

**Requisitos de Hardware:**
- CPU: 4+ cores (8+ recomendado)
- RAM: 8GB (16GB recomendado)
- Disco: 20GB livres

---

## 📄 Licença

Este projeto é baseado no [ServeRest](https://github.com/ServeRest/ServeRest) e mantém a licença **MIT**.

**Créditos ao projeto original:**
- Criado por [Paulo Gonçalves](https://github.com/PauloGoncalvesBH)
- Documentação: https://serverest.dev
- NPM: https://www.npmjs.com/package/serverest

---

## 🤝 Suporte

### Durante as Aulas

Pergunte ao professor ou colegas.

### Problemas Técnicos

1. Veja a seção [Problemas Comuns](#-problemas-comuns)
2. Execute `make status` e `make events`
3. Tente `make reset`

### Modo Verbose

Para debug detalhado:
```bash
make bootstrap VERBOSE=1
```

---

## 🚀 Começar Agora

```bash
# 1. Clone
git clone https://github.com/magnonta/server-rest.git
cd server-rest

# 2. Verifique
make check-prereqs

# 3. Crie
make bootstrap

# 4. Teste
curl http://localhost:30000/usuarios

# 5. Execute (escolha sua aula)
make lab-aula-01    # Testes de Carga
make lab-aula-02    # Testes de Segurança
```

**Boa aula! 🎓**

---

## 📞 Informações

**Repositório:** https://github.com/magnonta/server-rest  
**Branch Principal:** `curso-devops`  
**Versão:** v1.0-curso-devops  

**Última Atualização:** Janeiro 2025

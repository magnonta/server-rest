# Guia do Makefile - Curso DevOps QA

## 📚 Índice

- [Introdução](#introdução)
- [Pré-requisitos](#pré-requisitos)
- [Instalação de Ferramentas](#instalação-de-ferramentas)
- [Configuração Inicial](#configuração-inicial)
- [Comandos Principais](#comandos-principais)
- [Workflows por Aula](#workflows-por-aula)
- [Customização](#customização)
- [Troubleshooting](#troubleshooting)
- [Referência Completa](#referência-completa)

---

## 🎯 Introdução

Este Makefile foi criado para **automatizar todo o processo de setup, deploy e testes** do ambiente DevOps usado nas aulas de Testes de Carga em CI/CD.

### O que o Makefile faz?

- ✅ **Verifica** se todas as ferramentas necessárias estão instaladas
- 🚀 **Cria** um cluster Kubernetes local com kind
- 📦 **Instala** o Metrics Server para monitoramento
- 🔄 **Faz deploy** da aplicação ServeRest no cluster
- 🧪 **Executa** testes de carga (k6)
- 🔍 **Monitora** pods, HPA, logs e recursos
- 🧹 **Limpa** o ambiente quando necessário

### Por que usar o Makefile?

**Antes (manual):**
```bash
# 15+ comandos diferentes para configurar tudo
kind create cluster --config k8s/kind/kind-config.yaml
kubectl apply -f k8s/metrics-server/
kubectl wait --for=condition=ready pod -n kube-system -l k8s-app=metrics-server
kubectl create namespace serverest
kubectl apply -f k8s/serverest/
# ... e mais comandos
```

**Agora (automatizado):**
```bash
make bootstrap
```

---

## 📋 Pré-requisitos

### Ferramentas Necessárias

| Ferramenta | Versão Mínima | Descrição |
|------------|---------------|-----------|
| **Docker** | 20.10+ | Container runtime |
| **kubectl** | 1.28+ | CLI do Kubernetes |
| **kind** | 0.20+ | Kubernetes in Docker |
| **k6** | 0.45+ | Ferramenta de testes de carga |
| **Node.js** | 18+ | Runtime JavaScript |
| **npm** | 9+ | Gerenciador de pacotes |

### Verificar Pré-requisitos

Execute o comando abaixo para verificar se todas as ferramentas estão instaladas:

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

Próximo passo: make bootstrap
```

Se alguma ferramenta estiver faltando, veja a seção [Instalação de Ferramentas](#instalação-de-ferramentas).

---

## 🛠️ Instalação de Ferramentas

### Guia de Instalação

Para ver instruções detalhadas de instalação para seu sistema operacional:

```bash
make install-guide
```

### Instalação Automatizada

#### macOS (Homebrew)

```bash
make install-tools
```

Este comando instala automaticamente:
- Docker Desktop
- kubectl
- kind
- k6
- Node.js
- npm

#### Linux/Ubuntu/WSL2

```bash
make install-tools
```

Instala via apt e scripts oficiais.

#### Windows

**Recomendado:** Use WSL2 (Windows Subsystem for Linux) e siga as instruções para Linux.

**Alternativa:** Instale Docker Desktop e as ferramentas manualmente:
- Docker Desktop: https://www.docker.com/products/docker-desktop
- kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
- kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installing-with-a-package-manager
- k6: https://k6.io/docs/get-started/installation/
- Node.js: https://nodejs.org/

---

## ⚙️ Configuração Inicial

### 1. Verificar Pré-requisitos

```bash
make check-prereqs
```

### 2. (Opcional) Customizar Configurações

Copie o arquivo de exemplo:

```bash
cp .env.make.example .env.make
```

Edite `.env.make` para ajustar:

```bash
# Nome do cluster kind
KIND_CLUSTER_NAME=serverest-cluster

# Namespace do Kubernetes
K8S_NAMESPACE=serverest

# URL base da API
BASE_URL=http://localhost:30000

# Timeouts
POD_READY_TIMEOUT=120
METRICS_WAIT_TIME=30

# k6 Web Dashboard (dashboards HTML interativos)
K6_DASHBOARD=true        # gera dashboards HTML em k6/results/
K6_DASHBOARD_OPEN=false  # abre navegador durante execução

# Modo verbose (0 ou 1)
VERBOSE=0
```

### 3. Bootstrap do Ambiente

Execute o setup completo:

```bash
make bootstrap
```

**Este comando:**
1. ✅ Verifica pré-requisitos
2. 🏗️ Cria cluster kind (1 control-plane + 2 workers)
3. 📊 Instala Metrics Server
4. 🚀 Faz deploy do ServeRest
5. 🔌 Configura port-forward (localhost:30000)
6. ✅ Testa a API

**Tempo estimado:** 2-3 minutos

**Saída esperada:**
```
========================================
✅ AMBIENTE PRONTO! ✅
========================================

Próximos passos:
  1. Testar API: curl http://localhost:30000/usuarios
  2. Testes de carga: make test-load
  3. Ver status: make status
```

### 4. Verificar Status

```bash
make status
```

---

## 🚀 Comandos Principais

### Setup e Configuração

```bash
make bootstrap        # Setup completo (cluster + metrics + deploy + port-forward)
make status           # Mostra status de tudo (cluster, pods, HPA, recursos)
make clean-all        # Remove tudo (cluster, deploy, estado)
make reset            # Limpa e recria tudo (clean-all + bootstrap)
```

### Cluster Kubernetes

```bash
make cluster-create   # Cria cluster kind
make cluster-delete   # Remove cluster
make cluster-status   # Status do cluster e nodes
make cluster-restart  # Reinicia cluster (delete + create)
```

### Deploy da Aplicação

```bash
make deploy           # Faz deploy do ServeRest
make undeploy         # Remove deploy
make deploy-check     # Verifica status do deploy
make port-forward     # Inicia port-forward em background
make logs             # Mostra logs dos pods
make logs-follow      # Segue logs em tempo real (Ctrl+C para sair)
```

### Testes de Carga (k6)

```bash
make test-health      # Health check (10 req, 1 VU)
make test-smoke       # Smoke test (100 req, 5 VUs)
make test-load        # Teste de carga (1000 req, 50 VUs)
make test-stress      # Teste de stress (até 100 VUs)
make test-spike       # Teste de pico (spike de carga)
make test-soak        # Teste de imersão (5 min, carga constante)
make test-load-all    # Executa TODOS os testes em sequência
```

### Monitoramento e Debug

```bash
make top              # Recursos dos pods (CPU/Memória)
make watch-hpa        # Monitora HPA em tempo real
make events           # Eventos do cluster
make describe-pod     # Descreve um pod (interativo)
make debug-shell      # Shell em um pod (interativo)
```

### Ajuda

```bash
make help             # Ajuda resumida
make help-full        # Ajuda completa
make help-prereqs     # Ajuda sobre pré-requisitos
make help-cluster     # Ajuda sobre cluster
make help-deploy      # Ajuda sobre deploy
make help-tests       # Ajuda sobre testes
make help-debug       # Ajuda sobre debug
```

---

## 📖 Workflows por Aula

### 🎓 Aula 01: Testes de Carga em CI/CD

#### Setup Inicial (Primeira vez)

```bash
# 1. Verificar ferramentas
make check-prereqs

# 2. Criar ambiente completo
make bootstrap

# 3. Verificar que tudo está OK
make status
curl http://localhost:30000/usuarios
```

#### Workflow Completo da Aula 01

```bash
# Executa TUDO: bootstrap + todos os testes de carga
make lab-aula-01
```

**Este comando executa:**
1. ✅ Bootstrap do ambiente
2. 🧪 Health check
3. 🧪 Smoke test
4. 🧪 Load test
5. 🧪 Stress test
6. 🧪 Spike test
7. 🧪 Soak test

**Tempo estimado:** 10-15 minutos

#### Executar Testes Individualmente

```bash
# Health Check (10 requisições)
make test-health

# Smoke Test (100 requisições, 5 VUs)
make test-smoke

# Load Test (1000 requisições, 50 VUs)
make test-load

# Stress Test (escala até 100 VUs)
make test-stress

# Spike Test (pico súbito de carga)
make test-spike

# Soak Test (5 min de carga constante)
make test-soak
```

#### Monitoramento Durante os Testes

```bash
# Terminal 1: Executar teste
make test-load

# Terminal 2: Monitorar recursos
make watch-hpa

# Terminal 3: Ver logs
make logs-follow
```

#### Ao Final da Aula

```bash
# Ver status final
make status

# Opcional: Limpar ambiente
make clean-all
```

---

## 🎨 Customização

### Variáveis de Ambiente

Crie um arquivo `.env.make` (baseado em `.env.make.example`):

```bash
# Cluster
KIND_CLUSTER_NAME=meu-cluster
K8S_NAMESPACE=minha-app

# API
BASE_URL=http://localhost:30000

# Timeouts (em segundos)
POD_READY_TIMEOUT=180
METRICS_WAIT_TIME=45

# Debug
VERBOSE=1
```

### Modo Verbose

Para ver todos os comandos executados:

```bash
make bootstrap VERBOSE=1
make test-load VERBOSE=1
```

### k6 Web Dashboard

Os testes de carga podem gerar **dashboards HTML interativos** usando o k6 Web Dashboard nativo.

#### Ativar Dashboards

**Opção 1 — Via `.env.make` (permanente):**
```bash
K6_DASHBOARD=true
K6_DASHBOARD_OPEN=false
```

**Opção 2 — Via linha de comando (pontual):**
```bash
make test-smoke K6_DASHBOARD=true
make test-load-all K6_DASHBOARD=true
```

#### Abrir Dashboard em Tempo Real

Para acompanhar o teste ao vivo no navegador (http://localhost:5665):
```bash
make test-stress K6_DASHBOARD=true K6_DASHBOARD_OPEN=true
```

#### Onde ficam os dashboards?

Os dashboards HTML são salvos em `k6/results/`:
```
k6/results/
├── health-check-dashboard.html
├── smoke-test-dashboard.html
├── load-test-dashboard.html
├── stress-test-dashboard.html
├── spike-test-dashboard.html
└── soak-test-dashboard.html
```

Abra qualquer arquivo `.html` no navegador para visualizar:
```bash
open k6/results/smoke-test-dashboard.html       # macOS
xdg-open k6/results/smoke-test-dashboard.html   # Linux
```

> **Nota:** Os arquivos em `k6/results/` são ignorados pelo git (`.gitignore`). Eles são gerados localmente e não devem ser commitados.

### Ajustar Recursos do Cluster

Edite `k8s/kind/kind-config.yaml`:

```yaml
nodes:
  - role: control-plane
    extraPortMappings:
    - containerPort: 30000
      hostPort: 30000
  - role: worker
  - role: worker
  - role: worker  # Adicionar mais workers
```

### Ajustar Recursos do Deploy

Edite `k8s/serverest/deployment.yaml`:

```yaml
resources:
  requests:
    cpu: 200m        # Aumentar CPU
    memory: 256Mi    # Aumentar memória
  limits:
    cpu: 1000m
    memory: 1Gi
```

### Ajustar HPA

Edite `k8s/serverest/hpa.yaml`:

```yaml
minReplicas: 3       # Mínimo de pods
maxReplicas: 20      # Máximo de pods
targetCPUUtilizationPercentage: 60  # Threshold de CPU
```

---

## 🔧 Troubleshooting

### ❌ Docker não está rodando

**Erro:**
```
Verificando Docker (daemon)... ❌ ERRO (não está rodando)
```

**Solução:**
```bash
# macOS/Windows: Abrir Docker Desktop
# Linux:
sudo systemctl start docker
```

---

### ❌ Porta 30000 já está em uso

**Erro:**
```
Error: listen tcp :30000: bind: address already in use
```

**Solução:**
```bash
# Parar o processo que está usando a porta
lsof -ti:30000 | xargs kill -9

# Ou mudar a porta em .env.make
BASE_URL=http://localhost:30001
```

E ajuste em `k8s/kind/kind-config.yaml`:
```yaml
extraPortMappings:
- containerPort: 30000
  hostPort: 30001  # Nova porta
```

---

### ❌ Cluster já existe

**Erro:**
```
⚠️  Cluster já existe: serverest-cluster
Use 'make cluster-delete' para remover
```

**Solução:**
```bash
# Opção 1: Remover e recriar
make cluster-delete
make cluster-create

# Opção 2: Resetar tudo
make reset
```

---

### ❌ Pods não ficam prontos (timeout)

**Erro:**
```
Error: timed out waiting for the condition on pods
```

**Solução:**
```bash
# Ver status dos pods
kubectl get pods -n serverest

# Ver eventos
make events

# Ver logs de um pod com problema
make logs

# Aumentar timeout em .env.make
POD_READY_TIMEOUT=300
```

---

### ❌ Metrics Server não funciona

**Erro:**
```
Error from server (ServiceUnavailable): the server is currently unable to handle the request
```

**Solução:**
```bash
# Verificar se os pods do metrics-server estão rodando
kubectl get pods -n kube-system -l k8s-app=metrics-server

# Reinstalar metrics-server
kubectl delete -f k8s/metrics-server/
make metrics-install

# Aguardar mais tempo em .env.make
METRICS_WAIT_TIME=60
```

---

### ❌ k6 testes falham (connection refused)

**Erro:**
```
ERRO[0000] GoError: Get "http://localhost:30000/usuarios": dial tcp [::1]:30000: connect: connection refused
```

**Solução:**
```bash
# Verificar se port-forward está ativo
make status

# Verificar se a API responde
curl http://localhost:30000/usuarios

# Reiniciar port-forward
bash scripts/k8s/port-forward-manager.sh stop .make-state/port-forward.pid
make port-forward
```

---

### ❌ HPA mostra "unknown/50%"

**Sintoma:**
```
serverest-hpa   Deployment/serverest   cpu: <unknown>/50%
```

**Causa:** Metrics Server ainda não coletou métricas.

**Solução:**
```bash
# Aguardar 30-60 segundos
sleep 60
make status

# Verificar se metrics-server está OK
make top
```

---

### ❌ Estado inconsistente (flags .make-state)

**Sintoma:** Comandos falham dizendo que cluster não existe, mas ele existe.

**Solução:**
```bash
# Remover flags de estado
rm -rf .make-state/

# Verificar estado real
kind get clusters
kubectl get pods -n serverest

# Recriar flags manualmente OU fazer reset
make reset
```

---

### ❌ Erro "bash: make: command not found"

**Sistema:** Linux/WSL2

**Solução:**
```bash
sudo apt update
sudo apt install -y make
```

---

### ❌ Permission denied ao executar scripts

**Erro:**
```
bash: scripts/setup/verify-environment.sh: Permission denied
```

**Solução:**
```bash
# Dar permissão de execução
chmod +x scripts/**/*.sh
```

---

### 🧹 Limpeza Completa (Último Recurso)

Se nada funcionar:

```bash
# 1. Parar tudo
make clean-all

# 2. Remover containers órfãos
docker ps -a | grep serverest | awk '{print $1}' | xargs docker rm -f

# 3. Remover volumes
docker volume prune -f

# 4. Limpar estado
rm -rf .make-state/

# 5. Recriar tudo
make bootstrap
```

---

## 📚 Referência Completa

### Pré-requisitos e Instalação

| Comando | Descrição |
|---------|-----------|
| `make check-prereqs` | Verifica se todas as ferramentas estão instaladas |
| `make install-guide` | Mostra guia de instalação por plataforma |
| `make install-tools` | Instala ferramentas automaticamente (macOS/Linux) |

**Exemplos:**
```bash
# Verificar o que está faltando
make check-prereqs

# Ver como instalar no meu sistema
make install-guide

# Instalar tudo automaticamente (macOS)
make install-tools
```

---

### Cluster Kubernetes

| Comando | Descrição |
|---------|-----------|
| `make cluster-create` | Cria cluster kind com config de `k8s/kind/kind-config.yaml` |
| `make cluster-delete` | Remove cluster kind |
| `make cluster-status` | Mostra info e nodes do cluster |
| `make cluster-restart` | Reinicia cluster (delete + create) |

**Exemplos:**
```bash
# Criar cluster
make cluster-create

# Ver status dos nodes
make cluster-status

# Reiniciar cluster (útil após mudanças no kind-config.yaml)
make cluster-restart

# Remover cluster
make cluster-delete
```

---

### Metrics Server

| Comando | Descrição |
|---------|-----------|
| `make metrics-install` | Instala Metrics Server e aguarda ficar pronto |
| `make metrics-check` | Verifica se métricas estão disponíveis |

**Exemplos:**
```bash
# Instalar Metrics Server
make metrics-install

# Verificar se está funcionando
make metrics-check
make top
```

---

### Deploy da Aplicação

| Comando | Descrição |
|---------|-----------|
| `make deploy` | Faz deploy do ServeRest (namespace, config, deployment, service, HPA) |
| `make undeploy` | Remove todos os recursos do ServeRest |
| `make deploy-check` | Mostra status do deploy (pods, service, HPA, recursos) |
| `make port-forward` | Inicia port-forward em background (localhost:30000 → pod:3000) |

**Exemplos:**
```bash
# Deploy da aplicação
make deploy

# Verificar status
make deploy-check

# Iniciar port-forward
make port-forward

# Testar API
curl http://localhost:30000/usuarios

# Remover deploy
make undeploy
```

---

### Testes de Carga (k6)

| Comando | Descrição | VUs | Requisições | Duração |
|---------|-----------|-----|-------------|---------|
| `make test-health` | Health check básico | 1 | 10 | 10s |
| `make test-smoke` | Smoke test | 5 | 100 | 20s |
| `make test-load` | Teste de carga | 50 | 1000 | ~20s |
| `make test-stress` | Teste de stress (escala gradual) | 1→100 | Variável | 5 min |
| `make test-spike` | Teste de pico (spike súbito) | 1→100→1 | Variável | 3 min |
| `make test-soak` | Teste de imersão (longa duração) | 10 | Variável | 5 min |
| `make test-load-all` | Executa TODOS os testes em sequência | - | - | ~15 min |

**Exemplos:**
```bash
# Teste rápido
make test-health

# Teste de carga médio
make test-load

# Teste de stress (observar HPA scaling)
make test-stress

# Executar todos os testes
make test-load-all
```

**Scripts k6 usados:**
- `k6/scripts/00-health-check.js` - Health check
- `k6/scripts/01-smoke-test.js` - Smoke test
- `k6/scripts/02-load-test.js` - Load test
- `k6/scripts/03-stress-test.js` - Stress test
- `k6/scripts/04-spike-test.js` - Spike test
- `k6/scripts/05-soak-test.js` - Soak test

---

### Monitoramento e Debug

| Comando | Descrição |
|---------|-----------|
| `make logs` | Mostra últimas 100 linhas de logs de todos os pods |
| `make logs-follow` | Segue logs em tempo real (Ctrl+C para sair) |
| `make top` | Mostra uso de CPU/Memória dos pods |
| `make watch-hpa` | Monitora HPA em tempo real (Ctrl+C para sair) |
| `make events` | Mostra eventos do cluster |
| `make describe-pod` | Descreve um pod (interativo) |
| `make debug-shell` | Abre shell em um pod (interativo) |

**Exemplos:**
```bash
# Ver logs
make logs

# Seguir logs em tempo real
make logs-follow

# Ver recursos dos pods
make top

# Monitorar HPA durante teste de carga
# Terminal 1:
make watch-hpa
# Terminal 2:
make test-load

# Ver eventos (útil para debug)
make events

# Descrever um pod
make describe-pod
# Selecione o pod da lista

# Abrir shell em um pod
make debug-shell
# Selecione o pod
# Você estará dentro do container
```

---

### Workflows Completos

| Comando | Descrição | Tempo Estimado |
|---------|-----------|----------------|
| `make bootstrap` | Setup completo: cluster + metrics + deploy + port-forward | 2-3 min |
| `make lab-aula-01` | Workflow Aula 01: bootstrap + todos testes de carga | 10-15 min |
| `make demo` | Demo rápido: bootstrap + smoke test | 3-4 min |
| `make status` | Status completo do ambiente | 5s |
| `make clean` | Remove deploy e para port-forward | 10s |
| `make clean-all` | Remove tudo (deploy + cluster + estado) | 30s |
| `make reset` | Limpa tudo e recria (clean-all + bootstrap) | 3 min |

**Exemplos:**
```bash
# Setup inicial
make bootstrap

# Workflow da Aula 01 (completo)
make lab-aula-01

# Ver status de tudo
make status

# Limpar e recriar tudo
make reset
```

---

### Ajuda

| Comando | Descrição |
|---------|-----------|
| `make help` | Ajuda resumida (principais comandos) |
| `make help-full` | Ajuda completa (todos os comandos) |
| `make help-prereqs` | Ajuda sobre pré-requisitos |
| `make help-cluster` | Ajuda sobre cluster |
| `make help-deploy` | Ajuda sobre deploy |
| `make help-tests` | Ajuda sobre testes |
| `make help-debug` | Ajuda sobre debug |

**Exemplos:**
```bash
# Ver comandos principais
make help

# Ver todos os comandos
make help-full

# Ajuda sobre testes
make help-tests
```

---

### Comandos Originais do ServeRest (Preservados)

Estes comandos são do Makefile original do ServeRest e continuam funcionando:

| Comando | Descrição |
|---------|-----------|
| `make build` | Build da imagem Docker |
| `make run` | Roda container localmente |
| `make test` | Executa testes da aplicação |
| `make test-unit` | Executa testes unitários |
| `make lint` | Executa linter |

**Nota:** Estes comandos NÃO são necessários para as aulas. Use os workflows do Makefile DevOps.

---

## 📝 Notas Importantes

### Compatibilidade

- ✅ **macOS**: Totalmente suportado
- ✅ **Linux/Ubuntu**: Totalmente suportado
- ✅ **WSL2 (Windows)**: Totalmente suportado
- ❌ **Windows PowerShell**: NÃO suportado (use WSL2)

### Recursos do Sistema

**Mínimo recomendado:**
- **CPU:** 4 cores
- **RAM:** 8 GB
- **Disco:** 20 GB livres

**Para testes de stress:**
- **CPU:** 8+ cores
- **RAM:** 16+ GB

### Portas Usadas

- **30000:** ServeRest API (NodePort)
- **53xxx:** Kubernetes API Server (porta aleatória do kind)

### Estado do Ambiente

O Makefile usa arquivos em `.make-state/` para rastrear o estado:

```
.make-state/
├── cluster-created      # Cluster existe
├── metrics-installed    # Metrics Server instalado
├── deployed             # ServeRest deployado
└── port-forward.pid     # PID do processo port-forward
```

**Dica:** Se algo estiver inconsistente, remova `.make-state/` e recrie:
```bash
rm -rf .make-state/
make bootstrap
```

---

## 🎓 Dicas para Alunos

### Primeira Vez

1. **Verifique os pré-requisitos:**
   ```bash
   make check-prereqs
   ```

2. **Crie o ambiente:**
   ```bash
   make bootstrap
   ```

3. **Teste que está funcionando:**
   ```bash
   make status
   curl http://localhost:30000/usuarios
   ```

### Durante a Aula

1. **Use o workflow completo:**
   ```bash
   make lab-aula-01  # Aula 01: Testes de Carga
   ```

2. **Monitore em tempo real:**
   ```bash
   # Terminal 1: Status
   make watch-hpa
   
   # Terminal 2: Logs
   make logs-follow
   
   # Terminal 3: Testes
   make test-load
   ```

3. **Experimente:**
   ```bash
   # Ajustar HPA e ver o efeito
   kubectl edit hpa serverest-hpa -n serverest
   make test-load
   make status
   ```

### Ao Final

1. **Ver status final:**
   ```bash
   make status
   ```

2. **Opcional - Limpar:**
   ```bash
   make clean-all
   ```

### Entre Aulas

Se quiser manter o ambiente entre aulas:

```bash
# Não executar clean-all
# Na próxima aula, só verificar status:
make status

# Se algo estiver quebrado:
make reset
```

---

## 🆘 Suporte

### Documentação Adicional

- **Plano Geral das Aulas:** `docs/aulas/PLANO-GERAL.md`
- **Relatório de Testes de Lab:** `docs/TESTE-LAB-RELATORIO.md`
- **Scripts k6:** `k6/scripts/`
- **Manifests K8s:** `k8s/serverest/`

### Problemas Comuns

Consulte a seção [Troubleshooting](#troubleshooting) deste guia.

### Modo Verbose

Para debug detalhado:

```bash
make bootstrap VERBOSE=1
make test-load VERBOSE=1
```

---

## 📄 Licença

Este Makefile faz parte do material didático do Curso de DevOps QA - Pós-Graduação UNIESP.

---

**Versão:** 1.0  
**Última Atualização:** Janeiro 2025  
**Autor:** Professor DevOps QA - UNIESP

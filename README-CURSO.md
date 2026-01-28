# 🎓 ServeRest - Curso DevOps QA

> **Fork educacional do [ServeRest](https://github.com/ServeRest/ServeRest) para o Curso de DevOps QA - Pós-Graduação UNIESP**

[![GitHub tag](https://img.shields.io/github/v/tag/magnonta/server-rest?style=for-the-badge)](https://github.com/magnonta/server-rest/tags)
[![GitHub last commit](https://img.shields.io/github/last-commit/magnonta/server-rest?style=for-the-badge)](https://github.com/magnonta/server-rest/commits/curso-devops)
[![License](https://img.shields.io/github/license/magnonta/server-rest?style=for-the-badge)](LICENSE)

---

## 📚 Sobre Este Repositório

Este repositório contém a **infraestrutura completa** para as aulas de **Testes de Carga** e **Testes de Segurança em CI/CD** do curso de pós-graduação em DevOps QA.

### 🎯 O que foi adicionado ao ServeRest original?

- ✅ **Makefile com 60+ comandos** para automação completa
- ✅ **Kubernetes local** com kind (1 control-plane + 2 workers)
- ✅ **6 cenários de testes de carga** com k6
- ✅ **Testes de segurança** com Trivy e OWASP ZAP
- ✅ **CI/CD pipelines** com GitHub Actions
- ✅ **Documentação completa** (900+ linhas)
- ✅ **15 scripts auxiliares** para setup, testes e monitoramento
- ✅ **Slides das aulas** (282 slides em markdown)

---

## 🚀 Quick Start

### Pré-requisitos

- Docker
- kubectl
- kind
- k6
- Node.js
- npm

### Setup em 1 Comando

```bash
# Verificar pré-requisitos
make check-prereqs

# Criar ambiente completo (cluster + metrics + deploy + port-forward)
make bootstrap
```

**Tempo:** ~2-3 minutos

### Workflows das Aulas

#### 🧪 Aula 01: Testes de Carga em CI/CD

```bash
# Workflow completo (bootstrap + todos os testes de carga)
make lab-aula-01
```

**Executa:**
- Health check
- Smoke test
- Load test
- Stress test
- Spike test
- Soak test

**Tempo:** ~10-15 minutos

#### 🔒 Aula 02: Testes de Segurança em CI/CD

```bash
# Workflow completo (bootstrap + todos os testes de segurança)
make lab-aula-02
```

**Executa:**
- Trivy scan (imagem Docker)
- Trivy scan (Kubernetes manifests)
- OWASP ZAP scan

**Tempo:** ~5-10 minutos

---

## 📖 Documentação

| Documento | Descrição |
|-----------|-----------|
| [**Guia do Makefile**](docs/aulas/guias/MAKEFILE-GUIA.md) | Guia completo com todos os comandos (900+ linhas) |
| [**Plano Geral**](docs/aulas/PLANO-GERAL.md) | Plano completo das 2 aulas (700+ linhas) |
| [**Relatório de Testes**](docs/TESTE-LAB-RELATORIO.md) | Validação completa da infraestrutura |
| [**Slides Aula 01**](docs/aulas/aula-01-testes-carga/slides/) | 5 apresentações (282 slides) |

### 📂 Estrutura do Repositório

```
.
├── Makefile                    # 750+ linhas de automação
├── .env.make.example           # Template de configuração
├── k6/                         # Testes de carga
│   ├── scripts/                # 6 cenários de teste
│   └── modules/                # Módulos reutilizáveis
├── k8s/                        # Kubernetes
│   ├── kind/                   # Configuração do cluster
│   └── serverest/              # Manifests da aplicação
├── scripts/                    # Scripts auxiliares
│   ├── setup/                  # Instalação e verificação
│   ├── k8s/                    # Helpers Kubernetes
│   ├── load-testing/           # Suite k6
│   └── security/               # Scans de segurança
├── docs/                       # Documentação completa
│   └── aulas/                  # Material das aulas
├── .github/workflows/          # CI/CD pipelines
└── security/                   # Configurações de segurança
```

---

## 🎯 Principais Comandos

### Setup e Configuração

```bash
make bootstrap        # Setup completo (cluster + deploy + testes)
make status           # Status do ambiente
make clean-all        # Limpeza completa
make reset            # Clean + bootstrap
```

### Testes de Carga

```bash
make test-health      # Health check (10 req)
make test-smoke       # Smoke test (100 req)
make test-load        # Load test (1000 req, 50 VUs)
make test-stress      # Stress test (até 100 VUs)
make test-spike       # Spike test (pico súbito)
make test-soak        # Soak test (5 min)
make test-load-all    # Todos os testes
```

### Testes de Segurança

```bash
make test-trivy       # Trivy completo
make test-trivy-image # Scan imagem Docker
make test-trivy-k8s   # Scan Kubernetes
make test-zap         # OWASP ZAP
make test-security    # Todos os testes
```

### Monitoramento

```bash
make logs             # Logs dos pods
make logs-follow      # Seguir logs (Ctrl+C para sair)
make top              # Recursos (CPU/Memória)
make watch-hpa        # Monitorar HPA
make events           # Eventos do cluster
```

### Ajuda

```bash
make help             # Ajuda resumida
make help-full        # Ajuda completa
make help-tests       # Ajuda sobre testes
```

---

## 🎓 Material das Aulas

### Aula 01: Testes de Carga em CI/CD (8 horas)

**Tópicos:**
1. Introdução a Testes de Carga
2. Kubernetes e kind
3. Testes de Carga com k6
4. CI/CD com GitHub Actions
5. Revisão e Melhores Práticas

**Slides:** [docs/aulas/aula-01-testes-carga/slides/](docs/aulas/aula-01-testes-carga/slides/)

**Lab Prático:**
```bash
make lab-aula-01
```

---

### Aula 02: Testes de Segurança em CI/CD (8 horas)

**Tópicos:**
1. Fundamentos de Segurança em DevOps
2. Scan de Vulnerabilidades (Trivy)
3. OWASP ZAP e Testes de Segurança Web
4. Integração com CI/CD
5. Práticas de Segurança

**Lab Prático:**
```bash
make lab-aula-02
```

---

## 🛠️ Tecnologias Utilizadas

| Categoria | Tecnologia | Versão Mínima |
|-----------|-----------|---------------|
| **Container** | Docker | 20.10+ |
| **Orchestração** | Kubernetes (kind) | 1.28+ |
| **CLI** | kubectl | 1.28+ |
| **Load Testing** | k6 | 0.45+ |
| **Security Scanning** | Trivy | 0.45+ |
| **Security Testing** | OWASP ZAP | 2.14+ |
| **CI/CD** | GitHub Actions | - |
| **Runtime** | Node.js | 18+ |
| **Package Manager** | npm | 9+ |

---

## 📊 Funcionalidades

### Automação Completa (Makefile)

- ✅ Verificação de pré-requisitos
- ✅ Instalação automatizada (macOS/Linux)
- ✅ Criação de cluster kind
- ✅ Deploy de Metrics Server
- ✅ Deploy da aplicação ServeRest
- ✅ HPA (Horizontal Pod Autoscaler)
- ✅ Port-forward em background
- ✅ Suite completa de testes k6
- ✅ Scans de segurança
- ✅ Monitoramento e logs
- ✅ Limpeza e reset

### Testes de Carga (k6)

1. **Health Check** (10 req, 1 VU, 10s)
2. **Smoke Test** (100 req, 5 VUs, 20s)
3. **Load Test** (1000 req, 50 VUs, ~20s)
4. **Stress Test** (1→100 VUs, 5 min)
5. **Spike Test** (1→100→1 VUs, 3 min)
6. **Soak Test** (10 VUs, 5 min)

### Testes de Segurança

- **Trivy**: Scan de vulnerabilidades (imagem + K8s)
- **OWASP ZAP**: Scan de vulnerabilidades web

### CI/CD (GitHub Actions)

- **Workflow Aula 01**: Load testing pipeline
- **Workflow Aula 02**: Security testing pipeline

---

## 🎨 Customização

### Variáveis de Ambiente

Copie e edite `.env.make`:

```bash
cp .env.make.example .env.make
```

**Variáveis disponíveis:**
```bash
KIND_CLUSTER_NAME=serverest-cluster
K8S_NAMESPACE=serverest
BASE_URL=http://localhost:30000
POD_READY_TIMEOUT=120
METRICS_WAIT_TIME=30
VERBOSE=0
```

### Modo Verbose

```bash
make bootstrap VERBOSE=1
make test-load VERBOSE=1
```

---

## 🔧 Troubleshooting

### Problemas Comuns

| Problema | Solução |
|----------|---------|
| Docker não está rodando | `systemctl start docker` (Linux) ou abrir Docker Desktop |
| Porta 30000 em uso | `lsof -ti:30000 \| xargs kill -9` |
| Cluster já existe | `make cluster-delete && make cluster-create` |
| Pods não ficam prontos | `make events` e verificar logs |
| Metrics Server não funciona | Aguardar 60s ou `make metrics-install` |

### Ver Guia Completo

Consulte o [Guia do Makefile](docs/aulas/guias/MAKEFILE-GUIA.md) para troubleshooting detalhado.

---

## 📝 Compatibilidade

| Sistema | Suporte |
|---------|---------|
| macOS | ✅ Totalmente suportado |
| Linux/Ubuntu | ✅ Totalmente suportado |
| WSL2 (Windows) | ✅ Totalmente suportado |
| Windows PowerShell | ❌ Use WSL2 |

---

## 🤝 Sobre o ServeRest Original

Este fork é baseado no excelente projeto [ServeRest](https://github.com/ServeRest/ServeRest) criado por [Paulo Gonçalves](https://github.com/PauloGoncalvesBH).

**Diferenças:**
- ServeRest original: Foco em testes de API
- Este fork: Foco em DevOps, CI/CD, Load Testing e Security Testing

**Créditos ao projeto original:**
- Documentação: https://serverest.dev
- NPM: https://www.npmjs.com/package/serverest
- Docker: https://hub.docker.com/r/paulogoncalvesbh/serverest

---

## 📄 Licença

Este projeto mantém a mesma licença do ServeRest original: **MIT License**

---

## 👥 Autor do Fork Educacional

**Professor:** Magno Oliveira  
**Instituição:** UNIESP - Pós-Graduação  
**Curso:** DevOps QA  
**Período:** 2025  

---

## 🌟 Versões

- **v1.0-curso-devops** (Jan 2025): Release inicial com infraestrutura completa
  - Makefile automation
  - k6 load testing
  - Security testing
  - CI/CD pipelines
  - Documentação completa

---

## 📚 Links Úteis

- [Guia do Makefile](docs/aulas/guias/MAKEFILE-GUIA.md)
- [Plano das Aulas](docs/aulas/PLANO-GERAL.md)
- [Slides Aula 01](docs/aulas/aula-01-testes-carga/slides/)
- [Relatório de Testes](docs/TESTE-LAB-RELATORIO.md)

---

## 🚀 Começar Agora

```bash
# Clone o repositório
git clone https://github.com/magnonta/server-rest.git
cd server-rest

# Checkout da branch do curso
git checkout curso-devops

# Verificar pré-requisitos
make check-prereqs

# Setup completo
make bootstrap

# Executar lab da Aula 01
make lab-aula-01

# Ver status
make status

# Limpar tudo
make clean-all
```

**Boa aula! 🎓**

---

<details>
<summary>📖 README do ServeRest Original (clique para expandir)</summary>

---


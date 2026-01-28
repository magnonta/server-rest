# 🎓 ServeRest - Curso DevOps QA

> **Repositório educacional para o Curso de DevOps QA**  
> Aprenda Testes de Carga e Segurança em CI/CD com Kubernetes

[![GitHub](https://img.shields.io/badge/GitHub-magnonta%2Fserver--rest-blue?style=for-the-badge&logo=github)](https://github.com/magnonta/server-rest)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

---

## 🚀 Quick Start - 3 Comandos

```bash
# 1. Verificar se tem tudo instalado
make check-prereqs

# 2. Criar ambiente completo (cluster Kubernetes + aplicação)
make bootstrap

# 3. Executar testes
make lab-aula-01    # Testes de Carga
make lab-aula-02    # Testes de Segurança
```

**Pronto!** Em menos de 5 minutos você tem um cluster Kubernetes rodando localmente com testes automatizados. 🎉

---

## 📖 Documentação Completa

👉 **[Leia o README-CURSO.md](README-CURSO.md)** para documentação detalhada com:

- ✅ Guia passo a passo
- ✅ Lista completa de comandos
- ✅ Solução de problemas comuns
- ✅ Workflows das aulas
- ✅ Exemplos práticos

---

## 🎯 O Que Este Repositório Oferece

### Para Alunos

- **Makefile com 60+ comandos** - Automação completa
- **Ambiente Kubernetes local** - Cluster com kind (1 control-plane + 2 workers)
- **6 testes de carga com k6** - Health, Smoke, Load, Stress, Spike, Soak
- **Testes de segurança** - Trivy (vulnerabilidades) + OWASP ZAP (web)
- **CI/CD com GitHub Actions** - Pipelines prontos
- **Scripts auxiliares** - 15 scripts para setup e monitoramento

### Para Aprender

- ✅ Kubernetes prático
- ✅ Testes de carga (k6)
- ✅ Testes de segurança (Trivy, ZAP)
- ✅ CI/CD pipelines
- ✅ HPA (auto-scaling)
- ✅ Monitoramento

---

## 📋 Pré-requisitos

Você precisa ter instalado:

- Docker
- kubectl
- kind
- k6
- Node.js
- npm

**Não tem tudo instalado?**

```bash
# Ver guia de instalação para seu sistema
make install-guide

# Ou instalar automaticamente (macOS/Linux)
make install-tools
```

---

## 🎓 Workflows das Aulas

### Aula 01: Testes de Carga (8 horas)

```bash
make lab-aula-01
```

Executa automaticamente:
1. Health Check
2. Smoke Test (5 VUs)
3. Load Test (50 VUs)
4. Stress Test (até 100 VUs)
5. Spike Test (pico súbito)
6. Soak Test (5 minutos)

---

### Aula 02: Testes de Segurança (8 horas)

```bash
make lab-aula-02
```

Executa automaticamente:
1. Trivy - Scan de imagem Docker
2. Trivy - Scan de Kubernetes
3. OWASP ZAP - Scan de vulnerabilidades web

---

## 🛠️ Comandos Principais

```bash
# COMEÇAR
make bootstrap              # Cria ambiente completo
make status                 # Ver status

# TESTAR
make test-health            # Teste rápido
make test-load              # Teste de carga
make test-trivy             # Scan de segurança

# MONITORAR
make logs                   # Ver logs
make top                    # CPU/Memória
make watch-hpa              # Ver auto-scaling

# LIMPAR
make clean-all              # Remove tudo
make reset                  # Limpa e recria
```

**Ver todos os comandos:** `make help-full`

---

## 📊 Exemplo de Uso Completo

### Primeira Vez

```bash
# Clone o repositório
git clone https://github.com/magnonta/server-rest.git
cd server-rest

# Verifique as ferramentas
make check-prereqs

# Crie o ambiente (2-3 minutos)
make bootstrap

# Teste a API
curl http://localhost:30000/usuarios

# Execute os testes de carga (15 minutos)
make lab-aula-01

# Veja o status
make status

# Limpe (opcional)
make clean-all
```

---

## 🔧 Problemas Comuns

### Docker não está rodando
```bash
# macOS/Windows: Abra Docker Desktop
# Linux: sudo systemctl start docker
```

### Porta 30000 ocupada
```bash
lsof -ti:30000 | xargs kill -9
make port-forward
```

### Cluster já existe
```bash
make cluster-restart
```

### Pods não ficam prontos
```bash
make events
make logs
make reset  # Se necessário
```

**Mais soluções:** [README-CURSO.md - Problemas Comuns](README-CURSO.md#-problemas-comuns)

---

## 📁 Estrutura do Projeto

```
.
├── Makefile                    # 750+ linhas de automação
├── README.md                   # Este arquivo
├── README-CURSO.md             # Documentação completa
│
├── k6/                         # Testes de carga
│   └── scripts/                # 6 cenários
│
├── k8s/                        # Kubernetes
│   ├── kind/                   # Cluster config
│   └── serverest/              # App manifests
│
├── scripts/                    # Scripts auxiliares
│   ├── setup/                  # Instalação
│   ├── k8s/                    # Kubernetes helpers
│   ├── load-testing/           # k6 suite
│   └── security/               # Security scans
│
└── .github/workflows/          # CI/CD
```

---

## 💡 Dicas Rápidas

### 1. Use os Workflows
```bash
make lab-aula-01    # Tudo automatizado
```

### 2. Monitore em Tempo Real
```bash
# Terminal 1
make watch-hpa

# Terminal 2
make test-load
```

### 3. Quando Tiver Dúvidas
```bash
make help           # Comandos principais
make help-full      # Todos os comandos
```

### 4. Para Debug
```bash
make status         # Ver tudo
make events         # Ver eventos
make logs           # Ver logs
```

---

## 🌐 Compatibilidade

| Sistema | Status |
|---------|--------|
| macOS | ✅ |
| Linux/Ubuntu | ✅ |
| WSL2 | ✅ |
| Windows PowerShell | ❌ Use WSL2 |

---

## 📚 Recursos Adicionais

- **[Documentação Completa](README-CURSO.md)** - Guia detalhado
- **[ServeRest Original](https://github.com/ServeRest/ServeRest)** - Projeto base
- **[Documentação da API](https://serverest.dev)** - Endpoints disponíveis

---

## 🤝 Sobre o ServeRest Original

Este repositório é baseado no excelente projeto [ServeRest](https://github.com/ServeRest/ServeRest) criado por [Paulo Gonçalves](https://github.com/PauloGoncalvesBH).

**Diferenças:**
- **Original:** Foco em testes de API
- **Este fork:** Foco em DevOps, CI/CD, Load Testing e Security Testing

**Links do projeto original:**
- 🌐 Website: https://serverest.dev
- 📦 NPM: https://www.npmjs.com/package/serverest
- 🐳 Docker: https://hub.docker.com/r/paulogoncalvesbh/serverest

---

## 📄 Licença

MIT License - Baseado no [ServeRest](https://github.com/ServeRest/ServeRest)

---

## 🎓 Informações do Curso

**Curso:** DevOps para QA - Pós-Graduação UNIESP  
**Módulos:** 2 aulas de 8 horas cada  
**Tópicos:** Testes de Carga e Segurança em CI/CD

---

## 🚀 Começar Agora

```bash
git clone https://github.com/magnonta/server-rest.git
cd server-rest
make check-prereqs
make bootstrap
make lab-aula-01
```

**Boa aula!** 🎉

---

📖 **[Ver Documentação Completa →](README-CURSO.md)**

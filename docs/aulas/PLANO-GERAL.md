# PLANO GERAL - AULAS DE DEVOPS PARA QA
## Pós-Graduação em QA - Testes de Carga e Segurança em Pipelines CI/CD

---

## 📋 INFORMAÇÕES GERAIS

**Disciplina**: DevOps para QA  
**Carga Horária**: 2 sábados (8 horas cada = 16 horas totais)  
**Modalidade**: Presencial  
**Nível**: Iniciante  
**Público-Alvo**: Alunos de QA com conhecimento básico de testes  
**Plataforma**: Windows  
**Repositório**: [ServeRest](https://github.com/ServeRest/ServeRest)  

---

## 🎯 OBJETIVOS GERAIS

Ao final das duas aulas, os alunos serão capazes de:

1. **Compreender** os conceitos de testes de carga e suas métricas principais
2. **Configurar** ambiente Kubernetes local para testes
3. **Implementar** testes de carga automatizados com k6
4. **Observar** comportamento de autoscaling em tempo real
5. **Entender** os diferentes tipos de testes de segurança (SAST, DAST, SCA)
6. **Executar** análises de vulnerabilidades em dependências e containers
7. **Realizar** testes DAST com OWASP ZAP
8. **Integrar** testes de carga e segurança em pipelines CI/CD
9. **Analisar** relatórios e tomar decisões baseadas em dados
10. **Aplicar** boas práticas de DevSecOps no dia a dia

---

## 🛠️ FERRAMENTAS UTILIZADAS

### Infraestrutura
- **Docker Desktop** - Containerização
- **kind** (Kubernetes in Docker) - Cluster local
- **kubectl** - CLI do Kubernetes
- **Git** - Controle de versão

### Testes de Carga
- **k6** - Ferramenta de load testing
- **HPA** (Horizontal Pod Autoscaler) - Autoscaling no K8s
- **metrics-server** - Métricas do Kubernetes

### Segurança
- **Trivy** - Scanner de vulnerabilidades (deps + containers)
- **OWASP ZAP** - DAST (Dynamic Application Security Testing)
- **npm audit** - Análise de dependências Node.js
- **hadolint** - Linter para Dockerfile
- **CodeQL** - SAST (já integrado no repositório)

### CI/CD
- **GitHub Actions** - Pipeline de CI/CD
- **GitHub Security** - Security tab

---

## 📅 CRONOGRAMA DETALHADO

---

## 🎓 SÁBADO 1 - TESTES DE CARGA EM PIPELINES CI/CD

### **09:00 - 09:30 | Introdução Teórica (30min)**

**Objetivos**:
- Contextualizar testes de carga no ciclo de desenvolvimento
- Apresentar métricas e conceitos fundamentais
- Explicar importância de testes de carga em pipelines

**Conteúdo**:
1. O que são testes de carga?
   - Diferença entre testes funcionais e não-funcionais
   - Por que testar performance?
   - Consequências de não testar (exemplos reais)

2. Métricas importantes:
   - **RPS** (Requests Per Second) - Taxa de requisições
   - **Latência** - Tempo de resposta
   - **Percentis** (p50, p95, p99) - Distribuição de latência
   - **Throughput** - Volume de dados processados
   - **Taxa de Erro** - Percentual de falhas

3. Tipos de testes de carga:
   - **Smoke Test**: Funcionalidade básica (1-2 VUs)
   - **Load Test**: Carga esperada normal (10-50 VUs)
   - **Stress Test**: Encontrar limites (50-300+ VUs)
   - **Spike Test**: Picos repentinos (10→100→10 VUs)
   - **Soak Test**: Resistência longa duração (20 VUs por 30min+)

4. Por que no pipeline CI/CD?
   - Detectar regressões de performance
   - Validar antes de produção
   - Feedback rápido para desenvolvedores

**Slides**: `docs/aulas/aula-01-testes-carga/slides/01-introducao.md`

**Atividade**: Discussão sobre experiências dos alunos com problemas de performance

---

### **09:30 - 10:30 | Setup do Ambiente Windows (60min)**

**Objetivos**:
- Instalar todas as ferramentas necessárias
- Validar instalação
- Preparar ambiente para resto da aula

**Ferramentas a instalar**:

1. **Docker Desktop** (15min)
   - Download: https://www.docker.com/products/docker-desktop
   - Configuração: WSL2, 4GB RAM mínimo
   - Validação: `docker --version`

2. **Chocolatey** (5min)
   - Gerenciador de pacotes para Windows
   - Script de instalação via PowerShell (Admin)
   
3. **Ferramentas via Chocolatey** (20min)
   ```powershell
   choco install -y git kubernetes-cli kind k6 nodejs
   ```

4. **Validação completa** (10min)
   - Executar script: `scripts/setup/verify-installation.ps1`
   - Verificar versões:
     ```bash
     docker --version
     kubectl version --client
     kind version
     k6 version
     git --version
     node --version
     ```

5. **Clone do repositório** (10min)
   ```bash
   git clone https://github.com/ServeRest/ServeRest.git
   cd ServeRest
   ```

**Guia**: `docs/aulas/aula-01-testes-carga/guias/01-instalacao-windows.md`

**Slides**: `docs/aulas/aula-01-testes-carga/slides/02-metricas.md`

**Troubleshooting**: `docs/aulas/aula-01-testes-carga/troubleshooting.md`

---

### **10:30 - 10:45 | Coffee Break ☕**

---

### **10:45 - 12:00 | Criando Cluster Kubernetes Local (75min)**

**Objetivos**:
- Entender conceitos básicos de Kubernetes
- Criar cluster kind multi-node
- Fazer deploy do ServeRest no cluster
- Acessar aplicação localmente

**Conteúdo**:

1. **Kubernetes Básico** (15min)
   - Arquitetura: Control Plane + Worker Nodes
   - Conceitos fundamentais:
     - **Pod**: Menor unidade (container)
     - **Deployment**: Gerencia réplicas de pods
     - **Service**: Expõe pods (load balancer interno)
     - **HPA**: Horizontal Pod Autoscaler

2. **Criar Cluster kind** (15min)
   ```bash
   # Criar cluster com config customizada
   kind create cluster --config k8s/kind/kind-config.yaml
   
   # Verificar
   kubectl cluster-info --context kind-serverest-cluster
   kubectl get nodes
   ```

3. **Instalar metrics-server** (10min)
   ```bash
   # Necessário para HPA funcionar
   kubectl apply -f k8s/kind/metrics-server.yaml
   
   # Aguardar ficar pronto
   kubectl wait --for=condition=ready pod \
     -l k8s-app=metrics-server \
     -n kube-system --timeout=60s
   
   # Validar
   kubectl top nodes
   ```

4. **Deploy do ServeRest** (20min)
   ```bash
   # Aplicar todos os manifestos
   kubectl apply -f k8s/serverest/
   
   # Monitorar deploy
   kubectl get pods -n serverest --watch
   
   # Verificar service
   kubectl get svc -n serverest
   ```

5. **Acessar aplicação** (10min)
   - URL: http://localhost:3000
   - Testar endpoints no navegador/Postman
   - Ver documentação Swagger

6. **Comandos úteis** (5min)
   ```bash
   # Ver logs
   kubectl logs -f deployment/serverest -n serverest
   
   # Descrever pod
   kubectl describe pod <pod-name> -n serverest
   
   # Ver todos recursos
   kubectl get all -n serverest
   ```

**Guias**:
- `docs/aulas/aula-01-testes-carga/guias/02-kind-cluster.md`
- `docs/aulas/aula-01-testes-carga/guias/03-deploy-serverest.md`

**Slides**: `docs/aulas/aula-01-testes-carga/slides/04-kubernetes.md`

**Exercício**: Alunos criam cluster e fazem deploy do ServeRest

---

### **12:00 - 13:30 | Almoço 🍽️**

---

### **13:30 - 14:30 | Testes de Carga com k6 (60min)**

**Objetivos**:
- Entender sintaxe do k6
- Criar scripts de teste progressivos
- Executar testes e analisar resultados
- Definir thresholds (critérios de sucesso)

**Conteúdo**:

1. **Introdução ao k6** (10min)
   - Por que k6?
   - Sintaxe JavaScript ES6+
   - Estrutura básica de um teste
   
   ```javascript
   import http from 'k6/http';
   import { check } from 'k6';
   
   export default function() {
     const res = http.get('http://localhost:3000/usuarios');
     check(res, { 'status is 200': (r) => r.status === 200 });
   }
   ```

2. **Health Check** (5min)
   ```bash
   k6 run k6/scripts/00-health-check.js
   ```

3. **Smoke Test** (10min)
   - 1 VU por 1-2 minutos
   - Valida funcionalidade básica
   ```bash
   k6 run k6/scripts/01-smoke-test.js
   ```

4. **Load Test** (15min)
   - Simula carga normal (10-20 VUs)
   - Stages: Ramp up → Steady → Ramp down
   ```bash
   k6 run k6/scripts/02-load-test.js
   ```
   
   - Analisar saída:
     - http_req_duration (p95, p99)
     - http_req_failed (taxa de erro)
     - checks (validações)

5. **Stress Test** (10min)
   - Encontrar limites (até 300 VUs)
   - Observar degradação
   ```bash
   k6 run k6/scripts/03-stress-test.js
   ```

6. **Spike Test** (5min)
   - Picos repentinos (10→100→10 VUs)
   ```bash
   k6 run k6/scripts/04-spike-test.js
   ```

7. **Thresholds** (5min)
   - Definir critérios de sucesso/falha
   ```javascript
   thresholds: {
     'http_req_duration': ['p(95)<500'], // 95% < 500ms
     'http_req_failed': ['rate<0.01'],   // < 1% erro
   }
   ```

**Guias**:
- `docs/aulas/aula-01-testes-carga/guias/04-primeiro-teste-k6.md`

**Slides**: `docs/aulas/aula-01-testes-carga/slides/03-k6-fundamentos.md`

**Cheatsheet**: `docs/aulas/aula-01-testes-carga/cheatsheets/k6-cheatsheet.md`

**Exercício**: Alunos executam todos os tipos de teste

---

### **14:30 - 15:30 | Kubernetes Autoscaling (60min)**

**Objetivos**:
- Entender como HPA funciona
- Configurar HPA para ServeRest
- Observar pods escalando em tempo real
- Entender resource requests/limits

**Conteúdo**:

1. **Conceito de HPA** (10min)
   - Horizontal Pod Autoscaler
   - Como funciona:
     - Métricas (CPU, memória)
     - Fórmula: `desiredReplicas = ceil[currentReplicas * (currentMetricValue / targetMetricValue)]`
   - minReplicas vs maxReplicas
   - Comportamento de scaling up/down

2. **Resource Requests/Limits** (10min)
   ```yaml
   resources:
     requests:    # Mínimo necessário para criar pod
       cpu: 100m
       memory: 128Mi
     limits:      # Máximo que pod pode usar
       cpu: 500m
       memory: 512Mi
   ```
   
   - **Importante**: HPA usa `requests` como baseline!

3. **Verificar HPA** (5min)
   ```bash
   # Ver HPA
   kubectl get hpa -n serverest
   
   # Descrever (ver eventos)
   kubectl describe hpa serverest-hpa -n serverest
   ```

4. **Demonstração de Scaling** (20min)
   
   **Terminal 1**: Monitorar HPA
   ```bash
   watch kubectl get hpa -n serverest
   ```
   
   **Terminal 2**: Monitorar Pods
   ```bash
   watch kubectl get pods -n serverest
   ```
   
   **Terminal 3**: Executar Load Test
   ```bash
   k6 run k6/scripts/02-load-test.js
   ```
   
   **Observar**:
   - CPU% aumentando
   - HPA disparando scaling
   - Novos pods sendo criados
   - Load sendo distribuído
   - Após teste, pods sendo removidos

5. **Ajustar HPA** (10min)
   - Modificar `averageUtilization` de 50% para 30%
   - Observar scaling mais agressivo
   ```bash
   kubectl edit hpa serverest-hpa -n serverest
   ```

6. **Métricas** (5min)
   ```bash
   # CPU/Memória dos pods
   kubectl top pods -n serverest
   
   # CPU/Memória dos nodes
   kubectl top nodes
   ```

**Guias**:
- `docs/aulas/aula-01-testes-carga/guias/05-hpa-autoscaling.md`

**Slides**: `docs/aulas/aula-01-testes-carga/slides/04-kubernetes.md`

**Exercício**: Alunos executam load test e observam scaling

---

### **15:30 - 15:45 | Coffee Break ☕**

---

### **15:45 - 16:45 | Integração com GitHub Actions (60min)**

**Objetivos**:
- Entender estrutura de workflows do GitHub Actions
- Criar pipeline de teste de carga
- Configurar gatilhos e políticas
- Publicar relatórios

**Conteúdo**:

1. **GitHub Actions Básico** (10min)
   - O que são workflows?
   - Estrutura YAML
   - Jobs, Steps, Actions
   - Gatilhos (on push, on PR, schedule, manual)

2. **Workflow de Load Testing** (20min)
   
   Arquivo: `.github/workflows/aula-01-load-testing.yml`
   
   Passos:
   1. Checkout do código
   2. Setup Docker
   3. Criar cluster kind
   4. Deploy metrics-server
   5. Deploy ServeRest
   6. Instalar k6
   7. Executar smoke test
   8. Executar load test
   9. Upload de relatórios como artifacts
   10. Falhar job se thresholds não passarem

3. **Executar Workflow** (15min)
   - Push para branch
   - Acompanhar execução no GitHub
   - Ver logs
   - Baixar artifacts (relatórios)

4. **Políticas de Aprovação** (10min)
   - Branch protection rules
   - Required checks
   - Bloquear merge se load test falhar

5. **Scheduled Tests** (5min)
   - Executar testes de carga periodicamente
   ```yaml
   on:
     schedule:
       - cron: '0 2 * * *'  # Todo dia às 2h
   ```

**Guias**:
- `docs/aulas/aula-01-testes-carga/guias/06-pipeline-github.md`

**Slides**: `docs/aulas/aula-01-testes-carga/slides/05-ci-cd.md`

**Exercício**: Alunos criam e executam workflow

---

### **16:45 - 17:30 | Laboratório Prático (45min)**

**Atividades Práticas**:

1. **Criar cenário customizado** (15min)
   - Jornada completa de compra
   - Incluir: registro → login → listar produtos → criar carrinho → concluir compra

2. **Experimentar com diferentes cargas** (15min)
   - Modificar stages
   - Aumentar/diminuir VUs
   - Observar comportamento do sistema

3. **Ajustar HPA** (10min)
   - Modificar minReplicas, maxReplicas
   - Alterar targetCPUUtilizationPercentage
   - Testar scaling

4. **Troubleshooting** (5min)
   - Resolver problemas comuns
   - Ajudar colegas

**Exercícios**:
- `docs/aulas/aula-01-testes-carga/exercicios/exercicio-01-smoke-test.md`
- `docs/aulas/aula-01-testes-carga/exercicios/exercicio-02-load-test.md`
- `docs/aulas/aula-01-testes-carga/exercicios/exercicio-03-stress-test.md`
- `docs/aulas/aula-01-testes-carga/exercicios/exercicio-04-hpa.md`
- `docs/aulas/aula-01-testes-carga/exercicios/exercicio-05-pipeline.md`

**Gabaritos**: `docs/aulas/aula-01-testes-carga/exercicios/GABARITOS.md`

---

### **17:30 - 18:00 | Encerramento e Dúvidas (30min)**

**Conteúdo**:

1. **Revisão do que foi aprendido** (10min)
   - Tipos de testes de carga
   - Métricas importantes
   - k6 hands-on
   - Kubernetes + HPA
   - Pipeline CI/CD

2. **Discussão de casos reais** (10min)
   - Compartilhar experiências
   - Desafios em projetos

3. **Preparação para próximo sábado** (5min)
   - Overview de Segurança
   - O que esperar

4. **Perguntas e respostas** (5min)

**Tarefa de casa (opcional)**:
- Executar testes de carga em API própria
- Explorar mais cenários com k6
- Ler sobre DevSecOps

---

## 🔒 SÁBADO 2 - TESTES DE SEGURANÇA EM PIPELINES CI/CD

### **09:00 - 09:30 | Introdução à Segurança em DevOps (30min)**

**Objetivos**:
- Contextualizar segurança no ciclo DevOps
- Apresentar conceito de "Shift Left"
- Explicar tipos de testes de segurança
- Introduzir OWASP Top 10

**Conteúdo**:

1. **DevSecOps** (5min)
   - De DevOps para DevSecOps
   - "Shift Left Security": Testar cedo e frequentemente
   - Segurança como responsabilidade de todos

2. **Tipos de Testes de Segurança** (15min)
   
   - **SAST** (Static Application Security Testing)
     - Análise estática de código
     - Exemplos: CodeQL, SonarQube, Semgrep
     - Quando: Durante desenvolvimento
   
   - **DAST** (Dynamic Application Security Testing)
     - Testes "black box" na aplicação rodando
     - Exemplos: OWASP ZAP, Burp Suite
     - Quando: Após build, em staging
   
   - **SCA** (Software Composition Analysis)
     - Análise de dependências de terceiros
     - Exemplos: Trivy, Snyk, npm audit
     - Quando: Durante build e deploy
   
   - **Container Security**
     - Scan de imagens Docker
     - Exemplos: Trivy, Grype, Clair
     - Quando: Após build da imagem

3. **OWASP Top 10 API Security** (8min)
   1. Broken Object Level Authorization
   2. Broken Authentication
   3. Broken Object Property Level Authorization
   4. Unrestricted Resource Consumption
   5. Broken Function Level Authorization
   6. Unrestricted Access to Sensitive Business Flows
   7. Server Side Request Forgery (SSRF)
   8. Security Misconfiguration
   9. Improper Inventory Management
   10. Unsafe Consumption of APIs

4. **Por que automatizar segurança?** (2min)
   - Detectar vulnerabilidades cedo
   - Feedback rápido
   - Evitar deploy de código inseguro
   - Compliance e auditoria

**Slides**: 
- `docs/aulas/aula-02-testes-seguranca/slides/01-devsecops.md`
- `docs/aulas/aula-02-testes-seguranca/slides/02-owasp-top10.md`

---

### **09:30 - 10:30 | SCA - Análise de Dependências (60min)**

**Objetivos**:
- Entender risco de dependências vulneráveis
- Executar npm audit
- Usar Trivy para análise de dependências
- Corrigir vulnerabilidades encontradas

**Conteúdo**:

1. **Risco de Dependências** (5min)
   - Supply chain attacks
   - Dependências transitivas
   - CVEs (Common Vulnerabilities and Exposures)
   - CVSS Score (severity)

2. **npm audit** (15min)
   ```bash
   # Audit de dependências
   npm audit
   
   # Ver detalhes em JSON
   npm audit --json > security/reports/npm-audit.json
   
   # Corrigir automaticamente (quando possível)
   npm audit fix
   
   # Corrigir breaking changes (cuidado!)
   npm audit fix --force
   ```
   
   **Analisar output**:
   - Critical, High, Moderate, Low
   - Pacotes afetados
   - Caminho de dependência
   - Remediação sugerida

3. **Trivy para Dependências** (20min)
   ```bash
   # Scan de dependências
   trivy fs --scanners vuln .
   
   # Apenas critical e high
   trivy fs --severity CRITICAL,HIGH .
   
   # Output em JSON
   trivy fs --format json --output security/reports/trivy-deps.json .
   ```
   
   **Entender output**:
   - VulnerabilityID (CVE-2023-xxxxx)
   - PkgName (pacote afetado)
   - InstalledVersion vs FixedVersion
   - Severity
   - Description

4. **Correção de Vulnerabilidades** (15min)
   - Atualizar package.json
   - Testar após atualização
   - Verificar breaking changes
   - Re-executar audit

5. **.trivyignore** (5min)
   - Ignorar vulnerabilidades aceitas
   - Sempre com justificativa
   ```
   # CVE-2021-xxxxx - Não afeta nossa versão
   CVE-2021-xxxxx
   ```

**Guias**:
- `docs/aulas/aula-02-testes-seguranca/guias/01-npm-audit.md`
- `docs/aulas/aula-02-testes-seguranca/guias/02-trivy-dependencias.md`

**Slides**: `docs/aulas/aula-02-testes-seguranca/slides/03-sca.md`

**Exercício**: Alunos executam npm audit e Trivy

---

### **10:30 - 10:45 | Coffee Break ☕**

---

### **10:45 - 12:00 | Container Security (75min)**

**Objetivos**:
- Entender riscos em containers
- Analisar Dockerfile com hadolint
- Scanear imagens com Trivy
- Aplicar boas práticas de segurança

**Conteúdo**:

1. **Riscos em Containers** (10min)
   - Imagens base desatualizadas
   - Vulnerabilidades em layers
   - Containers rodando como root
   - Secrets em imagens
   - Tamanho de imagem (surface attack)

2. **hadolint - Linter para Dockerfile** (15min)
   
   **Já integrado no projeto!**
   
   ```bash
   # Verificar Dockerfile
   docker run --rm -i hadolint/hadolint < Dockerfile
   ```
   
   **Regras comuns**:
   - DL3006: Always tag the version of an image explicitly
   - DL3008: Pin versions in apt get install
   - DL3013: Pin versions in pip
   - DL4006: Set SHELL option -o pipefail
   
   **Analisar Dockerfile do ServeRest**:
   ```dockerfile
   FROM node:lts-alpine3.18@sha256:...  # ✅ Versão pinada
   
   RUN npm ci --production              # ✅ Lockfile
   
   ENV ENVIRONMENT='docker'             # ✅ Não há secrets
   
   # Usuário não-root seria ideal
   ```

3. **Trivy para Imagens Docker** (25min)
   
   **Build da imagem**:
   ```bash
   docker build -t serverest:test .
   ```
   
   **Scan básico**:
   ```bash
   # Scan da imagem
   trivy image serverest:test
   
   # Apenas critical
   trivy image --severity CRITICAL serverest:test
   
   # Output JSON
   trivy image --format json --output security/reports/trivy-image.json serverest:test
   ```
   
   **Scan de imagem remota**:
   ```bash
   trivy image paulogoncalvesbh/serverest:latest
   ```
   
   **Analisar resultados**:
   - Vulnerabilidades em base image (alpine)
   - Vulnerabilidades em dependências Node.js
   - Layers afetados
   - Remediação (atualizar base image)

4. **Boas Práticas de Segurança** (15min)
   
   ✅ **Multi-stage builds**:
   ```dockerfile
   # Build stage
   FROM node:18 AS build
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci
   COPY . .
   
   # Production stage
   FROM node:18-alpine
   WORKDIR /app
   COPY --from=build /app/node_modules ./node_modules
   COPY --from=build /app .
   USER node
   CMD ["npm", "start"]
   ```
   
   ✅ **Usar imagens base oficiais e leves**:
   - `node:18-alpine` vs `node:18`
   - Alpine é menor e menos vulnerabilidades
   
   ✅ **Não rodar como root**:
   ```dockerfile
   USER node
   ```
   
   ✅ **Remover cache e arquivos temporários**:
   ```dockerfile
   RUN npm ci --production && npm cache clean --force
   ```
   
   ✅ **Não incluir secrets**:
   - Usar build args
   - Runtime secrets (k8s secrets)
   - Não commitar .env

5. **Scan de Secrets** (10min)
   ```bash
   # Trivy secret scanning
   trivy fs --scanners secret .
   
   # Gitleaks (alternativa)
   docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect --source="/path" -v
   ```

**Guias**:
- `docs/aulas/aula-02-testes-seguranca/guias/03-trivy-containers.md`
- `docs/aulas/aula-02-testes-seguranca/guias/04-dockerfile-security.md`

**Slides**: `docs/aulas/aula-02-testes-seguranca/slides/04-container-security.md`

**Exercício**: Alunos melhoram Dockerfile e fazem scan

---

### **12:00 - 13:30 | Almoço 🍽️**

---

### **13:30 - 15:00 | DAST com OWASP ZAP (90min)**

**Objetivos**:
- Entender diferença entre SAST e DAST
- Instalar e configurar OWASP ZAP
- Executar diferentes tipos de scan
- Analisar relatórios de vulnerabilidades
- Corrigir problemas encontrados

**Conteúdo**:

1. **Introdução ao DAST** (10min)
   - Dynamic testing vs Static testing
   - Por que DAST?
     - Testa aplicação rodando
     - Simula atacante real
     - Encontra problemas de runtime
   - OWASP ZAP vs Burp Suite

2. **Instalação do ZAP** (15min)
   
   **Windows**:
   ```powershell
   choco install owasp-zap
   ```
   
   **Ou download manual**: https://www.zaproxy.org/download/
   
   **Configuração inicial**:
   - Modo: Headless (para automação)
   - API Key
   - Política de scan

3. **Tipos de Scan no ZAP** (10min)
   
   - **Baseline Scan**: Rápido, passivo, sem invasão
   - **Full Scan**: Completo, ativo, pode demorar
   - **API Scan**: Específico para APIs (usa OpenAPI spec)

4. **Baseline Scan** (15min)
   
   ```bash
   # Docker ZAP baseline
   docker run -v $(pwd):/zap/wrk/:rw \
     -t owasp/zap2docker-stable \
     zap-baseline.py \
     -t http://host.docker.internal:3000 \
     -r security/reports/zap-baseline.html
   ```
   
   **Analisar output**:
   - Risk levels: High, Medium, Low, Informational
   - Alertas comuns:
     - Missing Security Headers
     - Cookie without Secure flag
     - X-Content-Type-Options missing

5. **API Scan com OpenAPI** (25min)
   
   **ServeRest tem Swagger!**
   
   ```bash
   # Exportar OpenAPI spec
   curl http://localhost:3000/api-docs/ > docs/swagger.json
   
   # API Scan
   docker run -v $(pwd):/zap/wrk/:rw \
     -t owasp/zap2docker-stable \
     zap-api-scan.py \
     -t http://host.docker.internal:3000/api-docs \
     -f openapi \
     -r security/reports/zap-api-scan.html
   ```
   
   **Configurar autenticação**:
   - ZAP pode fazer login automático
   - Incluir token em requests
   - Testar endpoints autenticados

6. **Analisar Relatórios** (15min)
   
   **Vulnerabilidades comuns encontradas**:
   
   ✅ **Missing Security Headers**:
   - X-Content-Type-Options
   - X-Frame-Options
   - Strict-Transport-Security
   - Content-Security-Policy
   
   ✅ **Cookies Inseguros**:
   - Secure flag
   - HttpOnly flag
   - SameSite attribute
   
   ✅ **CORS Misconfiguration**:
   - Access-Control-Allow-Origin: *
   
   ✅ **SQL Injection** (teste):
   - Input validation
   
   ✅ **XSS** (Cross-Site Scripting):
   - Output encoding

7. **Correções** (10min)
   
   **ServeRest já tem security headers!**
   
   Ver em `src/app.js` - uso de `helmet` middleware
   
   **Testar com/sem segurança**:
   ```bash
   # Com segurança (default)
   npx serverest
   
   # Sem segurança (para comparar)
   npx serverest --nosec
   ```

**Guias**:
- `docs/aulas/aula-02-testes-seguranca/guias/05-owasp-zap.md`

**Slides**: `docs/aulas/aula-02-testes-seguranca/slides/05-dast.md`

**Cheatsheet**: `docs/aulas/aula-02-testes-seguranca/cheatsheets/owasp-zap-cheatsheet.md`

**Exercício**: Alunos executam ZAP scans

---

### **15:00 - 15:15 | Coffee Break ☕**

---

### **15:15 - 16:30 | SAST e Code Quality (75min)**

**Objetivos**:
- Entender análise estática de código
- Explorar CodeQL (GitHub)
- Usar SonarCloud para qualidade
- Identificar security hotspots

**Conteúdo**:

1. **Introdução ao SAST** (10min)
   - O que é análise estática?
   - Benefícios:
     - Detecta bugs antes de rodar código
     - Encontra padrões inseguros
     - Code smells
   - Ferramentas: CodeQL, SonarQube, Semgrep, ESLint

2. **CodeQL** (20min)
   
   **Já configurado no repositório!**
   
   Arquivo: `.github/workflows/codeql.yml`
   
   ```yaml
   - name: Initialize CodeQL
     uses: github/codeql-action/init@v2
     with:
       languages: javascript
   
   - name: Perform CodeQL Analysis
     uses: github/codeql-action/analyze@v2
   ```
   
   **Acessar resultados**:
   - GitHub → Security → Code scanning alerts
   
   **Tipos de alertas**:
   - Security vulnerabilities
   - Quality issues
   - Code maintenance
   
   **Exemplo de alertas**:
   - SQL injection potential
   - Hardcoded credentials
   - Unvalidated user input
   - Prototype pollution

3. **SonarCloud** (25min)
   
   **Já integrado no repositório!**
   
   Workflow: `.github/workflows/common_ci.yml` (job: sonarcloud)
   
   ```yaml
   - name: SonarCloud Scan
     uses: SonarSource/sonarcloud-github-action@master
   ```
   
   **Acessar**: https://sonarcloud.io/project/overview?id=ServeRest
   
   **Métricas principais**:
   - **Code Coverage**: % de código testado
   - **Duplications**: Código duplicado
   - **Maintainability**: Code smells
   - **Reliability**: Bugs
   - **Security**: Vulnerabilidades e hotspots
   
   **Security Hotspots**:
   - Áreas de código que precisam revisão
   - Não necessariamente vulnerabilidade
   - Require análise humana
   
   **Exemplos**:
   - Weak cryptography
   - Hardcoded secrets
   - Unsafe deserialization
   - SQL injection risk

4. **Quality Gates** (10min)
   
   **Definir critérios de aprovação**:
   ```yaml
   Quality Gate:
     - Coverage > 80%
     - Duplications < 3%
     - Maintainability Rating = A
     - Security Rating = A
     - No blocker issues
   ```
   
   **Bloquear merge se falhar**:
   - Branch protection rules
   - Required status checks
   - SonarCloud quality gate

5. **ESLint para Segurança** (10min)
   
   **Plugins de segurança**:
   ```bash
   npm install --save-dev eslint-plugin-security
   ```
   
   ```json
   {
     "plugins": ["security"],
     "extends": ["plugin:security/recommended"]
   }
   ```
   
   **Detecta**:
   - eval() usage
   - Non-literal require()
   - RegEx DoS
   - Unsafe crypto

**Guias**:
- `docs/aulas/aula-02-testes-seguranca/guias/06-codeql.md`

**Slides**: `docs/aulas/aula-02-testes-seguranca/slides/06-security-pipeline.md`

**Exercício**: Alunos exploram CodeQL e SonarCloud

---

### **16:30 - 17:30 | Pipeline de Segurança Completo (60min)**

**Objetivos**:
- Criar workflow GitHub Actions completo
- Integrar todos os testes de segurança
- Configurar security gates
- Gerar relatórios consolidados

**Conteúdo**:

1. **Arquitetura do Pipeline** (10min)
   
   ```
   Commit/PR
      ↓
   ┌─────────────────────┐
   │ Lint (ESLint)       │
   └──────────┬──────────┘
              ↓
   ┌─────────────────────┐
   │ SAST (CodeQL)       │
   └──────────┬──────────┘
              ↓
   ┌─────────────────────┐
   │ SCA (npm audit)     │
   │ SCA (Trivy deps)    │
   └──────────┬──────────┘
              ↓
   ┌─────────────────────┐
   │ Build Docker Image  │
   └──────────┬──────────┘
              ↓
   ┌─────────────────────┐
   │ Container Scan      │
   │ (Trivy image)       │
   │ (hadolint)          │
   └──────────┬──────────┘
              ↓
   ┌─────────────────────┐
   │ Deploy to Test Env  │
   └──────────┬──────────┘
              ↓
   ┌─────────────────────┐
   │ DAST (OWASP ZAP)    │
   └──────────┬──────────┘
              ↓
   ┌─────────────────────┐
   │ Security Report     │
   │ Upload Artifacts    │
   └─────────────────────┘
   ```

2. **Workflow Completo** (25min)
   
   Arquivo: `.github/workflows/aula-02-security-full.yml`
   
   **Jobs**:
   
   ```yaml
   jobs:
     lint:
       # ESLint
     
     sast:
       # CodeQL
     
     sca-npm:
       # npm audit
     
     sca-trivy:
       # Trivy dependencies
     
     build:
       # Build Docker image
     
     container-scan:
       # Trivy image scan
       # hadolint
     
     deploy-test:
       # Deploy to test environment
     
     dast:
       # OWASP ZAP scan
     
     security-report:
       # Consolidate reports
       # Upload artifacts
   ```

3. **Security Gates** (15min)
   
   **Políticas**:
   
   ✅ **CRITICAL vulnerabilities**: BLOQUEAR
   ✅ **HIGH vulnerabilities**: BLOQUEAR
   ⚠️ **MEDIUM vulnerabilities**: AVISAR (requer aprovação)
   ✅ **LOW vulnerabilities**: PERMITIR (criar issue)
   
   **Implementação**:
   ```yaml
   - name: Check Trivy Scan
     run: |
       CRITICAL=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' trivy-report.json)
       if [ "$CRITICAL" -gt 0 ]; then
         echo "❌ CRITICAL vulnerabilities found!"
         exit 1
       fi
   ```

4. **Relatórios** (10min)
   
   **Upload de artifacts**:
   ```yaml
   - uses: actions/upload-artifact@v3
     with:
       name: security-reports
       path: |
         security/reports/npm-audit.json
         security/reports/trivy-deps.json
         security/reports/trivy-image.json
         security/reports/zap-report.html
   ```
   
   **GitHub Security Tab**:
   - CodeQL alerts
   - Dependabot alerts
   - Secret scanning alerts

5. **Notificações** (5min)
   - Slack/Discord webhook
   - Email
   - GitHub Issues automáticos

**Guias**:
- `docs/aulas/aula-02-testes-seguranca/guias/07-security-pipeline.md`

**Exercício**: Alunos criam e executam pipeline completo

---

### **17:30 - 18:00 | Laboratório Final e Encerramento (30min)**

**Atividades**:

1. **Executar pipeline completo** (10min)
   - Commit changes
   - Trigger workflow
   - Acompanhar execução
   - Analisar resultados

2. **Análise de relatórios** (10min)
   - Baixar artifacts
   - Identificar vulnerabilidades
   - Priorizar correções

3. **Discussão de remediações** (5min)
   - Como corrigir cada tipo de vulnerabilidade?
   - Priorização baseada em risco
   - Balance entre segurança e funcionalidade

4. **Próximos passos** (5min)
   - Certificações recomendadas:
     - OWASP Top 10
     - Certified DevSecOps Professional
     - AWS/Azure Security
   - Materiais complementares
   - Comunidades

**Exercícios**:
- `docs/aulas/aula-02-testes-seguranca/exercicios/exercicio-01-scan-deps.md`
- `docs/aulas/aula-02-testes-seguranca/exercicios/exercicio-02-fix-vulns.md`
- `docs/aulas/aula-02-testes-seguranca/exercicios/exercicio-03-container.md`
- `docs/aulas/aula-02-testes-seguranca/exercicios/exercicio-04-zap.md`
- `docs/aulas/aula-02-testes-seguranca/exercicios/exercicio-05-pipeline.md`

**Gabaritos**: `docs/aulas/aula-02-testes-seguranca/exercicios/GABARITOS.md`

**Feedback da turma**

---

## 📊 AVALIAÇÃO DE APRENDIZADO

### **Critérios de Avaliação**:

#### **Aula 1 - Testes de Carga**:
- [ ] Criou cluster Kubernetes local com kind
- [ ] Fez deploy do ServeRest no cluster
- [ ] Executou diferentes tipos de testes k6
- [ ] Observou HPA escalando pods automaticamente
- [ ] Criou workflow GitHub Actions de load testing
- [ ] Analisou métricas e relatórios corretamente

#### **Aula 2 - Testes de Segurança**:
- [ ] Executou npm audit e corrigiu vulnerabilidades
- [ ] Usou Trivy para scan de dependências e containers
- [ ] Melhorou Dockerfile seguindo boas práticas
- [ ] Executou OWASP ZAP scan
- [ ] Explorou CodeQL e SonarCloud
- [ ] Criou pipeline de segurança completo

### **Exercícios Avaliativos (opcional)**:

#### **Trabalho 1 - Load Testing**:
Criar suite completa de testes de carga para API própria ou ServeRest:
- Smoke, Load, Stress, Spike tests
- Cenários de jornadas de usuário
- Thresholds configurados
- Pipeline CI/CD
- Relatório de análise

**Prazo**: 1 semana  
**Peso**: 50%

#### **Trabalho 2 - Security Scanning**:
Implementar pipeline de segurança completo:
- SCA (dependências)
- Container scanning
- DAST com ZAP
- Security gates
- Relatório de vulnerabilidades e remediações

**Prazo**: 1 semana  
**Peso**: 50%

---

## 📚 MATERIAIS DE APOIO

### **Para o Professor**:

1. **Slides** (formato Google Slides - templates em Markdown):
   - Aula 1: `docs/aulas/aula-01-testes-carga/slides/`
   - Aula 2: `docs/aulas/aula-02-testes-seguranca/slides/`

2. **Guias passo-a-passo**:
   - Instalação Windows
   - Setup Kubernetes
   - Configuração k6
   - Configuração Trivy/ZAP
   - Troubleshooting

3. **Exercícios com gabaritos**:
   - Exercícios práticos progressivos
   - Respostas detalhadas
   - Critérios de avaliação

4. **Scripts auxiliares**:
   - `scripts/setup/install-tools-windows.ps1`
   - `scripts/setup/verify-installation.ps1`
   - `scripts/load-testing/run-all-tests.sh`
   - `scripts/security/run-all-scans.sh`

5. **Backup plans**:
   - VMs na nuvem caso Docker Desktop falhe
   - Ambientes pré-configurados
   - Dados de teste

### **Para os Alunos**:

1. **Documentação completa**:
   - READMEs detalhados em cada diretório
   - Guias passo-a-passo
   - Troubleshooting

2. **Cheat sheets**:
   - `docs/aulas/aula-01-testes-carga/cheatsheets/k6-cheatsheet.md`
   - `docs/aulas/aula-01-testes-carga/cheatsheets/kubectl-cheatsheet.md`
   - `docs/aulas/aula-02-testes-seguranca/cheatsheets/trivy-cheatsheet.md`
   - `docs/aulas/aula-02-testes-seguranca/cheatsheets/owasp-zap-cheatsheet.md`

3. **Referências**:
   - `docs/referencias/links-uteis.md`
   - `docs/referencias/certificacoes.md`
   - `docs/referencias/proximos-passos.md`

4. **Exemplos**:
   - Resultados de testes k6
   - Relatórios de segurança
   - Screenshots

---

## 🔧 PRÉ-REQUISITOS

### **Hardware (Alunos)**:
- **RAM**: 8GB mínimo (16GB recomendado)
- **CPU**: 4 cores
- **Disco**: 20GB livres
- **SO**: Windows 10/11 Pro (para Hyper-V do Docker Desktop)

### **Software (Instalar antes da aula)**:

#### **Essenciais**:
1. Docker Desktop for Windows
2. Git for Windows (inclui Git Bash)
3. Chocolatey (gerenciador de pacotes)
4. Visual Studio Code (recomendado)
5. Navegador moderno (Chrome/Firefox/Edge)

#### **Via Chocolatey (instalar na aula)**:
```powershell
choco install -y kubernetes-cli kind k6 nodejs
```

#### **Opcionais**:
- Postman ou Insomnia (testar APIs)
- Windows Terminal (melhor terminal)

### **Conhecimentos Prévios**:
- ✅ Conceitos básicos de APIs REST
- ✅ Linha de comando (CMD/PowerShell/Bash)
- ✅ Git básico (clone, commit, push)
- ⚠️ Docker (desejável, mas não obrigatório)
- ⚠️ YAML (desejável, mas não obrigatório)

---

## ⚠️ RISCOS E MITIGAÇÕES

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Docker Desktop não funcionar | Alta | Alto | VMs na nuvem pré-configuradas como backup |
| kind não criar cluster | Média | Alto | Documentação detalhada de troubleshooting + suporte |
| Máquinas fracas de alunos | Média | Médio | Compartilhar cluster na nuvem se necessário |
| Testes demorarem muito | Baixa | Médio | Ter resultados pré-gravados para demonstração |
| OWASP ZAP scan demorar | Alta | Médio | Usar baseline scan (rápido) em vez de full scan |
| Problemas de rede/internet | Média | Alto | Download prévio de imagens Docker e ferramentas |
| Configuração Windows variar | Alta | Médio | Scripts automatizados + troubleshooting guide |
| Alunos com ritmos diferentes | Alta | Médio | Exercícios extras + mentoria peer-to-peer |

---

## 📈 MÉTRICAS DE SUCESSO

### **Indicadores de Sucesso da Aula**:

1. **Participação**: > 80% dos alunos conseguem completar exercícios
2. **Engajamento**: > 90% fazem perguntas e participam
3. **Ambiente**: > 90% conseguem configurar ambiente completo
4. **Testes k6**: > 80% executam todos os tipos de teste
5. **HPA**: > 80% observam scaling funcionando
6. **Pipeline**: > 70% criam workflow funcionando
7. **Segurança**: > 80% executam scans completos
8. **Satisfação**: NPS > 8/10

### **Objetivos de Aprendizado Alcançados**:

**Aula 1**:
- [ ] 90% entendem diferença entre tipos de teste de carga
- [ ] 80% criam e executam scripts k6
- [ ] 80% configuram HPA no Kubernetes
- [ ] 70% integram testes em pipeline CI/CD
- [ ] 90% interpretam métricas corretamente

**Aula 2**:
- [ ] 90% diferenciam SAST, DAST e SCA
- [ ] 90% executam npm audit e Trivy
- [ ] 80% configuram OWASP ZAP
- [ ] 70% implementam security gates no pipeline
- [ ] 80% priorizam correção de vulnerabilidades

---

## 🎓 CERTIFICADO (OPCIONAL)

Modelo de certificado de conclusão disponível em: `docs/certificado-template.md`

**Critérios para certificação**:
- Presença em ambas as aulas (> 75%)
- Completar pelo menos 70% dos exercícios
- Entregar trabalhos finais (se aplicável)

---

## 🔄 MELHORIAS CONTÍNUAS

### **Feedback dos Alunos**:
- Formulário de avaliação ao final de cada aula
- Sugestões de melhorias
- Tópicos adicionais desejados

### **Atualizações Futuras**:
- Adicionar módulo de Observabilidade (Prometheus/Grafana)
- Incluir GitLab CI/CD além de GitHub Actions
- Expandir para Azure DevOps
- Módulo de Performance Testing avançado
- Módulo de Chaos Engineering

---

## 📞 SUPORTE E CONTATO

### **Durante as Aulas**:
- Tire dúvidas diretamente com o professor
- Ajude colegas (aprender ensinando!)
- Use chat/grupo para dúvidas rápidas

### **Após as Aulas**:
- Issues no repositório do GitHub
- Grupo de WhatsApp/Discord da turma
- Email do professor

---

## 📖 REFERÊNCIAS BIBLIOGRÁFICAS

### **Livros**:
1. "The DevOps Handbook" - Gene Kim, Jez Humble, Patrick Debois, John Willis
2. "Accelerate" - Nicole Forsgren, Jez Humble, Gene Kim
3. "Site Reliability Engineering" - Google
4. "Security Engineering" - Ross Anderson

### **Websites**:
1. [k6 Documentation](https://k6.io/docs/)
2. [Kubernetes Documentation](https://kubernetes.io/docs/)
3. [OWASP Top 10](https://owasp.org/www-project-top-ten/)
4. [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
5. [Trivy Documentation](https://aquasecurity.github.io/trivy/)
6. [GitHub Actions Documentation](https://docs.github.com/en/actions)
7. [ServeRest](https://serverest.dev/)

### **Cursos Online**:
1. Kubernetes for Beginners - KodeKloud
2. DevSecOps - Practical DevSecOps
3. OWASP Top 10 - PluralSight
4. GitHub Actions - GitHub Learning Lab

### **Certificações Recomendadas**:
1. Certified Kubernetes Application Developer (CKAD)
2. Certified DevSecOps Professional (CDP)
3. OWASP Top 10 Certificate
4. GitHub Actions Certification

---

## 🎯 CONCLUSÃO

Este plano de aula oferece uma experiência **hands-on e prática** de DevOps para profissionais de QA, cobrindo:

✅ **Testes de Carga**: Desde conceitos até implementação completa com k6, Kubernetes e autoscaling  
✅ **Testes de Segurança**: SAST, DAST, SCA e container security integrados em pipeline  
✅ **CI/CD**: Automação completa com GitHub Actions  
✅ **Kubernetes**: Experiência prática com orquestração de containers  
✅ **DevSecOps**: Shift-left security aplicado na prática  

**Diferenciais**:
- Material 100% em Português
- Focado em Windows (realidade de muitos alunos)
- Repositório real e documentado (ServeRest)
- Ferramentas modernas e gratuitas
- Exercícios progressivos
- Aplicável imediatamente no dia a dia

**Após as aulas, os alunos estarão preparados para**:
- Implementar testes de carga em seus projetos
- Integrar segurança em pipelines CI/CD
- Usar Kubernetes para ambientes de teste
- Automatizar validações de performance e segurança
- Contribuir para cultura DevSecOps nas empresas

---

**Versão**: 1.0  
**Data**: Janeiro 2026  
**Autor**: Professor DevOps  
**Instituição**: Pós-Graduação em QA - UNIESP  

---

## 📂 ESTRUTURA DE ARQUIVOS DO REPOSITÓRIO

```
ServeRest/
│
├── docs/
│   ├── aulas/
│   │   ├── PLANO-GERAL.md                          # ⭐ Este arquivo
│   │   ├── aula-01-testes-carga/
│   │   │   ├── README.md
│   │   │   ├── slides/                             # Slides das apresentações
│   │   │   ├── guias/                              # Guias passo-a-passo
│   │   │   ├── exercicios/                         # Exercícios práticos
│   │   │   └── cheatsheets/                        # Referências rápidas
│   │   └── aula-02-testes-seguranca/
│   │       ├── README.md
│   │       ├── slides/
│   │       ├── guias/
│   │       ├── exercicios/
│   │       └── cheatsheets/
│   ├── referencias/                                # Links e materiais
│   └── troubleshooting/                            # Solução de problemas
│
├── k8s/                                            # Kubernetes manifests
│   ├── kind/                                       # Configuração kind
│   ├── serverest/                                  # Deploy ServeRest
│   └── README.md
│
├── k6/                                             # Testes de carga
│   ├── scripts/                                    # Scripts de teste
│   ├── modules/                                    # Módulos reutilizáveis
│   ├── data/                                       # Dados de teste
│   ├── scenarios/                                  # Cenários complexos
│   └── README.md
│
├── security/                                       # Configurações de segurança
│   ├── trivy/                                      # Config Trivy
│   ├── zap/                                        # Config OWASP ZAP
│   ├── policies/                                   # Políticas
│   └── README.md
│
├── .github/
│   └── workflows/
│       ├── aula-01-load-testing.yml                # Pipeline load testing
│       ├── aula-02-security-full.yml               # Pipeline security
│       └── ...
│
├── scripts/                                        # Scripts auxiliares
│   ├── setup/                                      # Setup Windows/Linux
│   ├── load-testing/                               # Automação k6
│   ├── security/                                   # Automação security
│   └── utils/                                      # Utilitários
│
└── examples/                                       # Exemplos e resultados
    ├── k6-results/
    ├── security-reports/
    └── screenshots/
```

---

**🎓 Boas aulas e sucesso no aprendizado de DevOps!** 🚀

# Aula 01 - Testes de Carga em Pipelines CI/CD

## Parte 4: Integrando Testes no CI/CD

**Duração**: 50 minutos  
**Objetivo**: Automatizar testes de carga no GitHub Actions

---

## Agenda

1. O que é CI/CD?
2. Por que automatizar testes de carga?
3. GitHub Actions básico
4. Estrutura do nosso pipeline
5. Configurando o workflow
6. Analisando resultados no CI
7. Pull Request reports

---

## O que é CI/CD?

**CI** = **C**ontinuous **I**ntegration  
**CD** = **C**ontinuous **D**elivery/Deployment

### Definição Simples

**Integração Contínua (CI)**:
- Código é integrado frequentemente (várias vezes ao dia)
- Testes automatizados rodam a cada commit
- Feedback rápido sobre problemas

**Entrega Contínua (CD)**:
- Código sempre pronto para deploy
- Deploy pode ser feito a qualquer momento
- Processo automatizado e confiável

---

## Pipeline CI/CD Tradicional

### Etapas Comuns

```
1. Commit → Push para repositório
         ↓
2. CI detecta mudança
         ↓
3. Build da aplicação
         ↓
4. Testes unitários
         ↓
5. Testes de integração
         ↓
6. Deploy (staging/produção)
```

**Problema**: Onde estão os testes de performance?  
**Resposta**: Muitas vezes ignorados! ❌

---

## Pipeline CI/CD com Testes de Carga

### Nossa Proposta

```
1. Commit → Push
         ↓
2. Build
         ↓
3. Testes unitários
         ↓
4. Build da imagem Docker
         ↓
5. Deploy em cluster local (kind)
         ↓
6. ⭐ TESTES DE CARGA ⭐
         ↓
7. Validar auto-scaling
         ↓
8. Report de resultados
```

---

## Por que Automatizar Testes de Carga?

### Benefícios

✅ **Detecção precoce**: Problema de performance antes de produção  
✅ **Regressões**: Evitar que mudança nova piore performance  
✅ **Confiança**: Deploy sem medo  
✅ **Consistência**: Mesmos testes, sempre  
✅ **Documentação**: Histórico de performance  
✅ **Economia**: Consertar em dev é 100x mais barato  

---

## Por que Automatizar Testes de Carga?

### Cenário Real

**Sem automação**:
```
Dev: "Otimizei a query!"
QA: "Ok, vou testar... daqui 2 dias"
[2 dias depois]
QA: "Na verdade piorou. Desfaz."
Dev: "😢 Já fiz outras mudanças..."
```

**Com automação**:
```
Dev: "Otimizei a query!" → Push
CI: [10 minutos depois] "p95 aumentou 300ms ❌"
Dev: "Ops! Vou reverter agora mesmo."
```

---

## Quando Executar Testes de Carga no CI?

### Estratégias

**1. A cada commit** (ideal, mas pode ser caro)
```yaml
on: [push]
```

**2. A cada Pull Request** (recomendado)
```yaml
on: [pull_request]
```

**3. Periodicamente** (ex: diariamente)
```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM todo dia
```

**4. Manualmente** (quando necessário)
```yaml
on: [workflow_dispatch]
```

---

## GitHub Actions: Conceitos Básicos

### Componentes Principais

**Workflow**: Arquivo YAML que define automação

**Job**: Conjunto de steps que rodam juntos

**Step**: Comando ou action individual

**Runner**: Máquina que executa o workflow

**Action**: Bloco reutilizável de código

---

## GitHub Actions: Exemplo Simples

### Hello World Workflow

```yaml
name: Hello World

on: [push]

jobs:
  greet:
    runs-on: ubuntu-latest
    steps:
      - name: Say hello
        run: echo "Hello, World!"
```

**O que acontece**:
1. A cada push
2. GitHub cria uma VM Ubuntu
3. Executa `echo "Hello, World!"`
4. Mostra output no log

---

## GitHub Actions: Exemplo com Checkout

### Acessando Código do Repo

```yaml
name: Build and Test

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Run tests
        run: npm test
```

**actions/checkout@v4**: Action que baixa código do repositório

---

## Nosso Workflow: Visão Geral

### Arquivo: `.github/workflows/aula-01-load-testing.yml`

**Objetivo**: 
1. Criar cluster Kubernetes (kind)
2. Deployar ServeRest
3. Executar testes k6
4. Validar auto-scaling
5. Gerar report

**Trigger**: Pull Request

---

## Estrutura do Workflow

### Jobs Principais

```yaml
jobs:
  load-testing:
    runs-on: ubuntu-latest
    steps:
      - Checkout
      - Setup kind
      - Deploy Metrics Server
      - Deploy ServeRest
      - Wait for pods
      - Run k6 tests
      - Monitor HPA
      - Upload results
      - Comment on PR
```

---

## Step 1: Checkout

### Baixar Código

```yaml
- name: Checkout repository
  uses: actions/checkout@v4
```

**O que faz**: Clona repositório para o runner

**Por que**: Precisamos dos arquivos k8s/ e k6/

---

## Step 2: Setup kind

### Criar Cluster Kubernetes

```yaml
- name: Create kind cluster
  uses: helm/kind-action@v1
  with:
    cluster_name: serverest-cluster
    config: k8s/kind/kind-config.yaml
    wait: 120s
```

**helm/kind-action**: Action oficial que:
- Instala kind
- Cria cluster
- Configura kubectl

---

## Step 3: Deploy Metrics Server

### Instalar Componente de Métricas

```yaml
- name: Install Metrics Server
  run: |
    kubectl apply -f k8s/kind/metrics-server.yaml
    kubectl wait --for=condition=ready pod \
      -l k8s-app=metrics-server \
      -n kube-system \
      --timeout=120s
```

**kubectl wait**: Aguarda pod ficar Ready antes de continuar

---

## Step 4: Deploy ServeRest

### Aplicar Manifests Kubernetes

```yaml
- name: Deploy ServeRest
  run: |
    kubectl apply -f k8s/serverest/00-namespace.yaml
    kubectl apply -f k8s/serverest/01-configmap.yaml
    kubectl apply -f k8s/serverest/02-deployment.yaml
    kubectl apply -f k8s/serverest/03-service.yaml
    kubectl apply -f k8s/serverest/04-hpa.yaml
```

---

## Step 5: Wait for Pods

### Garantir que Aplicação Está Pronta

```yaml
- name: Wait for ServeRest pods
  run: |
    kubectl wait --for=condition=ready pod \
      -l app=serverest \
      -n serverest \
      --timeout=180s
    
    # Validar que API responde
    kubectl run curl-test \
      --image=curlimages/curl:latest \
      --rm -i --restart=Never \
      -- curl -f http://serverest.serverest.svc.cluster.local:3000/
```

---

## Step 6: Install k6

### Preparar Ferramenta de Teste

```yaml
- name: Install k6
  run: |
    sudo gpg -k
    sudo gpg --no-default-keyring \
      --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
      --keyserver hkp://keyserver.ubuntu.com:80 \
      --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
    echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
      | sudo tee /etc/apt/sources.list.d/k6.list
    sudo apt-get update
    sudo apt-get install k6
```

---

## Step 7: Port Forward

### Expor API para k6

```yaml
- name: Port forward ServeRest
  run: |
    kubectl port-forward -n serverest \
      svc/serverest 3000:3000 &
    sleep 5
    curl http://localhost:3000/
```

**Por que**: k6 roda fora do cluster, precisa acessar via localhost

**&**: Roda em background

---

## Step 8: Run k6 Tests

### Executar Testes de Carga

```yaml
- name: Run k6 health check
  run: k6 run k6/scripts/00-health-check.js

- name: Run k6 smoke test
  run: k6 run k6/scripts/01-smoke-test.js

- name: Run k6 load test
  run: |
    k6 run \
      --out json=load-test-results.json \
      --summary-export=load-test-summary.json \
      k6/scripts/02-load-test.js
```

**--out json**: Salvar resultados detalhados  
**--summary-export**: Salvar sumário

---

## Step 9: Monitor HPA

### Capturar Auto-scaling

```yaml
- name: Monitor HPA during test
  run: |
    echo "HPA Status before test:"
    kubectl get hpa -n serverest
    
    echo "Running load test with HPA monitoring..."
    kubectl get hpa -n serverest -w &
    HPA_PID=$!
    
    k6 run k6/scripts/02-load-test.js
    
    kill $HPA_PID
    
    echo "Final HPA status:"
    kubectl get hpa -n serverest
    kubectl describe hpa serverest-hpa -n serverest
```

---

## Step 10: Check HPA Scaling

### Validar que Auto-scaling Funcionou

```yaml
- name: Verify HPA scaled
  run: |
    REPLICAS=$(kubectl get hpa serverest-hpa -n serverest \
      -o jsonpath='{.status.currentReplicas}')
    
    echo "Current replicas: $REPLICAS"
    
    if [ "$REPLICAS" -gt 2 ]; then
      echo "✅ HPA scaled successfully!"
    else
      echo "⚠️ HPA did not scale"
      exit 1
    fi
```

**Lógica**: Se HPA não escalou além de 2 pods, teste falha

---

## Step 11: Upload Results

### Salvar Artefatos

```yaml
- name: Upload k6 results
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: k6-results
    path: |
      load-test-results.json
      load-test-summary.json
    retention-days: 30
```

**if: always()**: Faz upload mesmo se teste falhar  
**retention-days**: Guardar por 30 dias

---

## Step 12: Generate Report

### Criar Sumário Legível

```yaml
- name: Generate test report
  run: |
    echo "# Load Testing Report" > report.md
    echo "" >> report.md
    echo "## Summary" >> report.md
    
    P95=$(jq -r '.metrics.http_req_duration.values["p(95)"]' \
      load-test-summary.json)
    
    echo "- **p95**: ${P95}ms" >> report.md
    
    FAIL_RATE=$(jq -r '.metrics.http_req_failed.values.rate' \
      load-test-summary.json)
    
    echo "- **Error Rate**: ${FAIL_RATE}%" >> report.md
```

---

## Step 13: Comment on PR

### Postar Resultados no Pull Request

```yaml
- name: Comment PR with results
  if: github.event_name == 'pull_request'
  uses: actions/github-script@v7
  with:
    script: |
      const fs = require('fs');
      const report = fs.readFileSync('report.md', 'utf8');
      
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: report
      });
```

---

## Workflow Completo: Visão de Alto Nível

```yaml
name: Load Testing

on:
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  load-testing:
    runs-on: ubuntu-latest
    steps:
      # 1. Setup
      - Checkout
      - Create kind cluster
      - Install Metrics Server
      
      # 2. Deploy
      - Deploy ServeRest
      - Wait for ready
      
      # 3. Test
      - Install k6
      - Run tests
      
      # 4. Report
      - Upload results
      - Comment PR
```

---

## Executando o Workflow

### Como Testar

**Método 1: Pull Request**
```bash
git checkout -b test-load-pipeline
git commit --allow-empty -m "Test load pipeline"
git push origin test-load-pipeline
# Criar PR no GitHub
```

**Método 2: Manual (workflow_dispatch)**
- Ir para GitHub → Actions
- Selecionar workflow
- Clicar "Run workflow"

---

## Analisando Resultados no CI

### GitHub Actions UI

**Onde encontrar**:
1. GitHub repo → **Actions** tab
2. Selecionar workflow run
3. Clicar no job "load-testing"
4. Ver logs de cada step

**Artefatos**:
- Actions → Workflow run → **Artifacts**
- Download `k6-results.zip`
- Contém JSONs com métricas completas

---

## Interpretando Logs do CI

### Output k6 no Log

```
✓ status é 200
✓ resposta < 500ms

checks.........................: 100.00%
data_received..................: 150 kB
http_req_duration..............: avg=245ms p(95)=450ms
http_req_failed................: 0.00%
http_reqs......................: 1200
```

**Buscar**:
- ✓ (checks passando)
- ❌ (checks falhando)
- Thresholds (pass/fail)
- Métricas principais

---

## Pull Request Comment

### Exemplo de Report Automático

```markdown
# Load Testing Report

## Summary
- **p95**: 450ms ✅
- **p99**: 680ms ✅
- **Error Rate**: 0.00% ✅
- **Total Requests**: 1200
- **Throughput**: 40 req/s

## HPA Scaling
- Initial Replicas: 2
- Max Replicas during test: 5 ✅
- Final Replicas: 2

## Verdict
All thresholds passed! ✅
```

---

## Thresholds no CI

### Critérios de Pass/Fail

```javascript
export const options = {
  thresholds: {
    http_req_duration: ['p(95)<500'],   // ← Deve passar
    http_req_failed: ['rate<0.01'],     // ← Deve passar
    checks: ['rate>0.95']                // ← Deve passar
  }
};
```

**Se qualquer threshold falhar**:
- k6 retorna exit code 1
- GitHub Actions marca step como ❌
- Workflow falha
- PR não pode ser merged (se configurado)

---

## Branch Protection Rules

### Exigir Testes de Carga Passando

**GitHub Settings** → **Branches** → **Add rule**

```
✅ Require status checks to pass before merging
   ✅ load-testing
```

**Resultado**: Não pode fazer merge se testes falharem!

---

## Otimizações do Pipeline

### Reduzir Tempo de Execução

**1. Cache de dependências**:
```yaml
- uses: actions/cache@v4
  with:
    path: ~/.k6
    key: ${{ runner.os }}-k6
```

**2. Testes paralelos**:
```yaml
strategy:
  matrix:
    test: [smoke, load, stress]
```

**3. Testes mais curtos no PR**:
```javascript
// PR: testes rápidos
// Main: testes completos
```

---

## Comparação de Performance

### Detectar Regressões

**Estratégia**: Comparar com baseline

```yaml
- name: Compare with baseline
  run: |
    CURRENT_P95=$(jq -r '.metrics.http_req_duration.values["p(95)"]' \
      load-test-summary.json)
    
    BASELINE_P95=450  # Salvo anteriormente
    
    if (( $(echo "$CURRENT_P95 > $BASELINE_P95 * 1.1" | bc -l) )); then
      echo "⚠️ Performance degradation: ${CURRENT_P95}ms vs ${BASELINE_P95}ms"
      exit 1
    fi
```

**1.1** = 10% de margem

---

## Salvando Baseline

### Armazenar Métricas de Referência

**Opção 1**: Arquivo no repositório
```bash
echo "P95_BASELINE=450" >> baseline.env
git add baseline.env
```

**Opção 2**: GitHub Secrets
```
Settings → Secrets → New repository secret
Name: P95_BASELINE
Value: 450
```

**Opção 3**: Database/API externa
```bash
curl -X POST https://metrics-api.com/baseline \
  -d '{"p95": 450}'
```

---

## Notificações

### Alertas de Falha

**Slack**:
```yaml
- name: Notify Slack
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "⚠️ Load tests failed on PR #${{ github.event.number }}"
      }
```

---

## Custos do CI/CD

### GitHub Actions Pricing

**Free tier**:
- Repositórios públicos: **Ilimitado** ✅
- Repositórios privados: **2000 minutos/mês**

**Nosso pipeline**:
- ~10 minutos por execução
- 20 PRs/mês = 200 minutos
- **Bem dentro do free tier!** ✅

---

## Boas Práticas CI/CD

### Checklist

✅ **Fail fast**: Testes rápidos primeiro (smoke antes de load)  
✅ **Isolamento**: Cada workflow em namespace próprio  
✅ **Limpeza**: Deletar recursos após teste  
✅ **Logs claros**: Usar echo para explicar steps  
✅ **Artefatos**: Salvar resultados importantes  
✅ **Timeout**: Evitar workflows eternos  
✅ **Retry**: Comandos de rede podem falhar transientemente  

---

## Troubleshooting CI

### Problemas Comuns

**Pipeline timeout**:
```yaml
jobs:
  load-testing:
    timeout-minutes: 30  # ← Adicionar
```

**kind cluster não cria**:
```yaml
# Verificar nos logs:
- Docker está disponível?
- Disk space suficiente?
```

**k6 não encontra API**:
```bash
# Adicionar debug:
kubectl get pods -n serverest
kubectl logs <pod> -n serverest
curl -v http://localhost:3000/
```

---

## Demo ao Vivo

### Vamos Ver o Pipeline em Ação!

**Passos**:
1. Criar branch
2. Fazer commit (pode ser vazio)
3. Push para GitHub
4. Criar Pull Request
5. Ver workflow executar
6. Analisar logs
7. Ver report no PR

---

## Exercício Prático 1

### Adicionar Novo Teste ao Pipeline

**Tarefa**:
1. Criar teste `k6/scripts/06-meu-teste.js`
2. Adicionar step no workflow para executar esse teste
3. Fazer commit e push
4. Verificar no CI

**Tempo**: 15 minutos

---

## Exercício Prático 2

### Criar Workflow de Stress Test

**Tarefa**: Criar novo workflow `.github/workflows/stress-test.yml`
- Trigger: Manual (`workflow_dispatch`)
- Executar apenas `03-stress-test.js`
- Salvar resultados
- Sem validação de HPA (pode não escalar)

**Tempo**: 20 minutos

---

## Exercício Prático 3

### Simular Regressão de Performance

**Tarefa**:
1. Editar teste para ter threshold impossível: `p(95)<1`
2. Fazer commit e PR
3. Ver workflow falhar
4. Analisar mensagem de erro
5. Reverter mudança

**Tempo**: 10 minutos

**Objetivo**: Entender como regressões são detectadas

---

## Próximos Passos

### Onde Evoluir

**Nível Intermediário**:
- Testes em múltiplos ambientes (staging, prod-like)
- Comparação automática com baseline
- Dashboards de performance histórica

**Nível Avançado**:
- Testes de carga distribuídos
- Integração com ferramentas APM (New Relic, Datadog)
- Testes de performance em escala (milhares de VUs)

---

## Ferramentas Complementares

### Observabilidade

**Grafana k6**: Visualização de métricas k6
```bash
k6 run --out influxdb=http://localhost:8086/k6 script.js
```

**Prometheus**: Métricas do Kubernetes
```yaml
kubectl apply -f prometheus-operator.yaml
```

**Grafana**: Dashboards
```bash
helm install grafana grafana/grafana
```

---

## Resumo da Parte 4

### O que Aprendemos

✅ Conceitos de CI/CD  
✅ GitHub Actions básico  
✅ Estrutura completa de pipeline de load testing  
✅ Criar cluster kind no CI  
✅ Executar k6 automaticamente  
✅ Validar auto-scaling  
✅ Gerar reports automáticos  
✅ Comentar em Pull Requests  
✅ Branch protection rules  

---

## Recursos para Aprofundar

### Links Úteis

**GitHub Actions**:
- https://docs.github.com/en/actions

**kind no CI**:
- https://github.com/helm/kind-action

**k6 CI/CD**:
- https://k6.io/docs/testing-guides/automated-performance-testing/

---

## Conclusão da Aula 1

### O que Cobrimos Hoje

✅ **Parte 1**: Conceitos de testes de carga  
✅ **Parte 2**: Kubernetes e kind  
✅ **Parte 3**: k6 para testes de carga  
✅ **Parte 4**: CI/CD com GitHub Actions  

**Você agora sabe**:
- Tipos de testes de performance
- Criar clusters Kubernetes locais
- Escrever testes k6
- Automatizar tudo no CI/CD!

---

## Próximo Sábado

### Aula 02: Testes de Segurança em Pipelines CI/CD

**Tópicos**:
- Tipos de testes de segurança
- SAST, DAST, Dependency Scanning
- Trivy para containers
- OWASP ZAP para APIs
- Pipeline de segurança completo

**Prepare-se**: Tudo que aprendemos hoje será usado!

---

## Avaliação da Aula

### Feedback Rápido (5 minutos)

**Nos diga**:
1. O que foi mais útil?
2. O que foi mais difícil?
3. O que poderia melhorar?
4. Dúvidas que ficaram?

**Link**: [formulário de feedback]

---

## Tarefa para Casa (Opcional)

### Praticar e Explorar

1. **Criar testes adicionais**: Testar outros endpoints
2. **Experimentar diferentes stages**: Spike test personalizado
3. **Explorar métricas**: Criar métricas customizadas
4. **Melhorar pipeline**: Adicionar mais validações
5. **Estudar**: Ler documentação k6 e GitHub Actions

---

## Recursos de Apoio

### Material Disponível

📂 **Repositório**: github.com/ServeRest/ServeRest  
📖 **Guias**: `/docs/aulas/aula-01-testes-carga/guias/`  
📝 **Exercícios**: `/docs/aulas/aula-01-testes-carga/exercicios/`  
🔖 **Cheatsheets**: Comandos kubectl, k6, kind  
🆘 **Troubleshooting**: Problemas comuns e soluções  

---

## Comunidade

### Continue Aprendendo

**Discord/Slack**: [link da comunidade]  
**LinkedIn**: Compartilhe o que aprendeu!  
**GitHub**: Contribua com melhorias  
**Blog**: Escreva sobre sua experiência  

**#AprendaEmPublico**

---

## Certificado

### Conclusão do Módulo

**Requisitos**:
✅ Participação em >80% da aula  
✅ Exercícios práticos completos  
✅ Pipeline funcionando  

**Emissão**: Ao final da Aula 02

---

## Obrigado!

### Até o Próximo Sábado!

**Contato**: [seu-email@exemplo.com]  
**Material**: [link-do-repositorio]  
**Slides**: [link-google-slides]  

**Dúvidas**: Pode enviar email durante a semana!

---

## Q&A Final

### Últimas Perguntas

**Tempo**: 10 minutos

**Qualquer dúvida é válida!**

---

# Notas para o Professor

## Timing Sugerido (50 minutos)

- Slides 1-15: Conceitos CI/CD (10 min)
- Slides 16-35: GitHub Actions e estrutura do workflow (15 min)
- Slides 36-50: Demo ao vivo (15 min)
- Slides 51-60: Exercícios e Q&A (10 min)

## Demonstração Recomendada

1. **Abrir GitHub**: Mostrar interface Actions
2. **Criar branch e PR**: Fazer ao vivo
3. **Ver workflow executar**: Acompanhar em tempo real
4. **Mostrar logs**: Explicar cada step
5. **Ver comment no PR**: Mostrar report gerado

## Preparação Antes da Aula

- ✅ Criar repositório de exemplo no GitHub
- ✅ Testar workflow completo
- ✅ Preparar PR de exemplo
- ✅ Screenshots de sucesso e falha
- ✅ Ter segunda conta GitHub para simular reviewer

## Exercícios - Distribuição

- **Exercício 1**: Fazer junto (demonstração guiada)
- **Exercício 2**: Individual (circular pela sala)
- **Exercício 3**: Demonstrar resultado esperado

## Checkpoint Final

Garantir que todos:
- ✅ Entendem estrutura de workflow
- ✅ Sabem onde ver logs no GitHub
- ✅ Conseguem interpretar resultados
- ✅ Entendem thresholds e pass/fail

## Material Extra

- Link para workflows de exemplo de projetos open source
- Lista de actions úteis do marketplace
- Documentação de YAML syntax

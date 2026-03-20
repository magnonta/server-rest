# Guia Completo: Testes de Carga em Pipelines CI/CD com Kubernetes

> **Pós-Graduação em QA - UNIESP**
> Disciplina: DevOps para QA | Aula 01 - Testes de Carga

---

## Sumário

1. [Introdução](#1-introdução)
2. [O que são Testes de Carga?](#2-o-que-são-testes-de-carga)
3. [Tipos de Testes de Carga](#3-tipos-de-testes-de-carga)
4. [Métricas Fundamentais](#4-métricas-fundamentais)
5. [Ferramentas Utilizadas](#5-ferramentas-utilizadas)
6. [Arquitetura do Projeto](#6-arquitetura-do-projeto)
7. [Pipeline Standalone (npm)](#7-pipeline-standalone-npm)
8. [Pipeline Kubernetes (kind)](#8-pipeline-kubernetes-kind)
9. [Scripts k6 em Detalhe](#9-scripts-k6-em-detalhe)
10. [Kubernetes e Autoscaling (HPA)](#10-kubernetes-e-autoscaling-hpa)
11. [Como Analisar os Resultados](#11-como-analisar-os-resultados)
12. [Dashboards e Relatórios](#12-dashboards-e-relatórios)
13. [Resultados Reais do Pipeline](#13-resultados-reais-do-pipeline)
14. [Problemas Comuns e Soluções](#14-problemas-comuns-e-soluções)
15. [Glossário](#15-glossário)
16. [Referências](#16-referências)

---

## 1. Introdução

Este guia documenta todo o sistema de **testes de carga automatizados** que construímos durante o curso. O objetivo é que você consiga:

- Entender **por que** testamos carga em pipelines CI/CD
- Compreender **cada tipo** de teste e quando usar
- Saber **como funciona** a pipeline passo a passo
- **Interpretar** os resultados e tomar decisões

Usamos a API **ServeRest** (uma API REST educacional) como alvo dos testes, o **k6** como ferramenta de carga e o **Kubernetes** com HPA (Horizontal Pod Autoscaler) para demonstrar auto-scaling sob pressão.

### Por que testes de carga no pipeline?

Imagine que você fez um deploy na sexta-feira. Segunda de manhã, o sistema cai porque não aguenta o volume de usuários. Testes de carga no pipeline CI/CD **detectam esse problema antes do deploy** — automaticamente, em cada mudança de código.

---

## 2. O que são Testes de Carga?

Testes de carga simulam múltiplos usuários acessando o sistema simultaneamente para verificar como ele se comporta sob pressão. Diferente de testes funcionais (que verificam *se* algo funciona), testes de carga verificam *como* algo funciona quando muita gente usa ao mesmo tempo.

### Analogia do Restaurante

Pense num restaurante:
- **Teste funcional**: O prato sai correto? O pagamento funciona?
- **Teste de carga**: O que acontece quando 200 pessoas chegam ao mesmo tempo? A cozinha dá conta? O garçom atende em tempo aceitável? O sistema de pagamento trava?

### O que medimos?

| Pergunta | Métrica |
|----------|---------|
| Quanto tempo demora para responder? | **Latência** (tempo de resposta) |
| Quantas requisições por segundo aguenta? | **Throughput** (RPS) |
| Qual % das requisições falha? | **Taxa de erro** |
| Qual o pior caso de tempo de resposta? | **Percentis** (p95, p99) |

---

## 3. Tipos de Testes de Carga

Cada tipo simula um cenário diferente do mundo real. A tabela abaixo resume todos:

| Tipo | VUs | Duração | Objetivo | Cenário Real |
|------|-----|---------|----------|--------------|
| **Health Check** | 1 | 10s | API está no ar? | Monitoramento básico |
| **Smoke** | 1 | 45s-1m30 | Funciona sem carga? | Deploy recém-feito |
| **Load** | 10→20 | 4m-9m | Aguenta carga normal? | Dia típico de uso |
| **Stress** | 10→300 | 5m30-11m | Qual o limite? | Pico inesperado |
| **Spike** | 10→100→10 | 2m30-4m30 | Aguenta picos súbitos? | Black Friday, viral |
| **Soak** | 20 | 14m-40m | Degrada com o tempo? | Operação contínua |

> **Nota**: As durações menores são do modo CI (pipeline), as maiores são execução local.

### 3.1 Health Check

O teste mais simples. Apenas verifica se a API está respondendo.

```
VUs ─┐
  1  │████████████████████
     └──────────────────── Tempo
     0s                 10s
```

**Quando usar**: Antes de qualquer outro teste, para garantir que o alvo está acessível.

### 3.2 Smoke Test

Executa com carga mínima (1 VU) para validar que as funcionalidades básicas estão operando.

```
VUs ─┐
  1  │░░████████████████████
     └──────────────────────── Tempo
     0s   warmup    teste estável
```

**Quando usar**: Após deploy, antes de testes mais pesados. Se o smoke falha, não adianta rodar os outros.

### 3.3 Load Test

Simula a carga esperada em produção. Sobe gradualmente de 0 para 10, depois para 20 VUs, e desce de volta.

```
VUs ─┐
 20  │            ████████████
 10  │   ████████│            │
  0  │░░│        │            │░░
     └──────────────────────────── Tempo
        ramp-up  estável      ramp-down
```

**Quando usar**: Para validar que o sistema aguenta a carga diária normal. Este é o teste mais importante para a maioria dos projetos.

**Cenário executado**: Registro de usuário → Login → Listar produtos → Buscar produto → Criar produto

### 3.4 Stress Test

Aumenta a carga progressivamente até encontrar o ponto de quebra do sistema.

```
VUs ──┐
 300  │                     ████
 200  │               ██████    │
 100  │         ██████          │
  50  │   ██████                │
  10  │░░│                      │░░░
      └─────────────────────────────── Tempo
         warmup → stress crescente → recovery
```

**Quando usar**: Para descobrir os limites do sistema. "Até quantos usuários simultâneos aguentamos?"

**O que observar**: Em qual nível de VUs as respostas começam a degradar? Qual o primeiro erro? O sistema se recupera depois que a carga diminui?

### 3.5 Spike Test

Simula picos repentinos — a carga sobe de 10 para 100 VUs em 10 segundos, duas vezes.

```
VUs ──┐
 100  │     ██         ██
  10  │████│  │████████│  │████
   0  │    │  │        │  │    │░░
      └─────────────────────────── Tempo
        normal SPIKE normal SPIKE normal
```

**Quando usar**: Para simular situações como Black Friday, campanhas virais, menção em TV. O sistema consegue absorver o choque e se recuperar?

### 3.6 Soak Test (Endurance)

Mantém carga constante moderada por um longo período (30+ minutos).

```
VUs ─┐
 20  │   ████████████████████████████████████
  0  │░░│                                    │░░
     └────────────────────────────────────────── Tempo
       ramp-up      30 minutos constante      ramp-down
```

**Quando usar**: Para detectar problemas que só aparecem com o tempo — memory leaks, degradação de banco de dados, esgotamento de conexões.

---

## 4. Métricas Fundamentais

### 4.1 Latência (Tempo de Resposta)

Quanto tempo o servidor leva para responder uma requisição.

- **Média** (`avg`): Visão geral, mas pode esconder problemas
- **Mediana** (`med` / `p50`): Metade das requisições são mais rápidas que isso
- **p95**: 95% das requisições são mais rápidas que isso — **a métrica mais usada na indústria**
- **p99**: 99% das requisições são mais rápidas que isso — mostra os "piores casos"

**Por que usar percentis em vez de média?**

Imagine 100 requisições: 99 levam 2ms e 1 leva 5000ms.
- Média: 51ms (parece OK!)
- p99: 5000ms (mostra o problema real!)

A média esconde outliers. O p95 e p99 mostram a experiência dos usuários mais afetados.

### 4.2 Throughput (RPS - Requests Per Second)

Quantas requisições por segundo o sistema processa.

- **Smoke test**: ~1.5 RPS (1 VU, pouca pressão)
- **Load test**: ~7 RPS (10-20 VUs, carga normal)
- **Stress test**: ~194 RPS (até 300 VUs!)
- **Spike test**: ~93 RPS (picos de 100 VUs)

### 4.3 Taxa de Erro

Percentual de requisições que falharam (status HTTP 4xx/5xx ou timeout).

| Nível | Interpretação |
|-------|--------------|
| 0% | Perfeito |
| < 1% | Aceitável para produção |
| 1-5% | Atenção — investigar |
| 5-10% | Problema sério |
| > 10% | Sistema degradado, ação urgente |

### 4.4 Checks

Validações customizadas dentro dos scripts k6. Exemplo: "O status é 200?", "O body contém a lista de produtos?"

A taxa de checks mostra se o sistema não só responde, mas responde **corretamente**.

---

## 5. Ferramentas Utilizadas

### k6

Ferramenta de testes de carga de código aberto da Grafana Labs. Scripts em JavaScript (ES6+).

**Por que k6?**
- Scripts como código (versionável no Git)
- Alta performance (escrito em Go)
- Métricas ricas nativamente
- Fácil de integrar em CI/CD
- Web Dashboard embutido

### kind (Kubernetes in Docker)

Cria clusters Kubernetes locais usando containers Docker como "nodes". Ideal para CI/CD porque:
- Rápido de criar/destruir
- Não precisa de cloud
- Funciona em GitHub Actions

### kubectl

CLI oficial do Kubernetes. Usamos para deploy, monitoramento e coleta de métricas.

### GitHub Actions

Plataforma de CI/CD do GitHub. Os pipelines são definidos em YAML em `.github/workflows/`.

---

## 6. Arquitetura do Projeto

### Estrutura de Arquivos

```
ServeRest/
├── .github/workflows/
│   ├── pipeline-standalone.yml      # Pipeline sem Kubernetes
│   └── pipeline-kubernetes.yml      # Pipeline com kind + HPA
│
├── k6/
│   ├── modules/
│   │   ├── config.js                # Configurações, stages, thresholds
│   │   └── serverest-api.js         # Funções da API (criarUsuario, listarProdutos, etc.)
│   ├── scripts/
│   │   ├── 00-health-check.js       # Health check simples
│   │   ├── 01-smoke-test.js         # Smoke test
│   │   ├── 02-load-test.js          # Load test com fluxo completo
│   │   ├── 03-stress-test.js        # Stress test até 300 VUs
│   │   ├── 04-spike-test.js         # Spike test com picos súbitos
│   │   ├── 05-soak-test.js          # Soak test de longa duração
│   │   └── generate-dashboard.py    # Gerador de dashboard Plotly
│   └── results/                     # Relatórios gerados (não commitados)
│
├── k8s/
│   ├── kind/
│   │   ├── kind-config-ci.yaml      # Config do cluster (single-node CI)
│   │   └── metrics-server.yaml      # Metrics server para HPA
│   └── serverest/
│       ├── 00-namespace.yaml        # Namespace "serverest"
│       ├── 01-configmap.yaml        # Configurações da app
│       ├── 02-deployment.yaml       # Deployment (2 réplicas, resources, probes)
│       ├── 03-service.yaml          # Service NodePort (porta 30000)
│       ├── 04-hpa.yaml              # HPA (2-10 réplicas, CPU 50%, Mem 80%)
│       └── ci-overrides/
│           └── hpa-ci.yaml          # HPA otimizado para CI (max 4 réplicas)
```

### Módulo de Configuração (`config.js`)

Centraliza todas as constantes reutilizáveis:

- **`BASE_URL`**: URL da API (vem da env var ou default `localhost:3000`)
- **`getStages(type)`**: Retorna stages adequados ao ambiente (CI ou local)
- **`DEFAULT_THRESHOLDS`**: Critérios de sucesso padrão
- **`DEFAULT_HEADERS`**: Headers HTTP padrão

**Modo CI vs Local**: Quando `K6_CI=true` (definido no pipeline), os stages são mais curtos para economizar tempo no runner. A lógica de teste é a mesma — só muda a duração.

| Teste | Local | CI | Economia |
|-------|-------|----|----------|
| Smoke | 1m30s | 45s | -45s |
| Load | 9m | 4m | -5m |
| Stress | 11m | 5m30s | -5m30s |
| Spike | 4m30s | 2m30s | -2m |
| **Total** | **~27m** | **~13m** | **~14m** |

### Módulo de API (`serverest-api.js`)

Encapsula todas as chamadas à API ServeRest em funções reutilizáveis:

| Função | Endpoint | Descrição |
|--------|----------|-----------|
| `criarUsuario()` | `POST /usuarios` | Cria um usuário |
| `fazerLogin()` | `POST /login` | Faz login e retorna token |
| `listarUsuarios()` | `GET /usuarios` | Lista todos os usuários |
| `buscarUsuario()` | `GET /usuarios/:id` | Busca usuário por ID |
| `criarProduto()` | `POST /produtos` | Cria um produto (requer token) |
| `listarProdutos()` | `GET /produtos` | Lista todos os produtos |
| `buscarProduto()` | `GET /produtos/:id` | Busca produto por ID |
| `criarCarrinho()` | `POST /carrinhos` | Cria um carrinho |
| `concluirCompra()` | `DELETE /carrinhos/concluir-compra` | Conclui a compra |
| `thinkTime()` | — | Simula tempo de reflexão do usuário |

Cada função inclui **checks** (validações) que verificam se a resposta é válida. Todas têm **null guards** para evitar crash quando o servidor está indisponível (body null).

---

## 7. Pipeline Standalone (npm)

**Arquivo**: `.github/workflows/pipeline-standalone.yml`

A pipeline mais simples. Roda o ServeRest diretamente com `npm start` (sem Kubernetes).

### Fluxo

```
1. Checkout do código
2. Setup Node.js 18
3. npm ci (instalar dependências)
4. npm start & (iniciar ServeRest em background)
5. Aguardar API ficar acessível (até 30 tentativas)
6. Setup k6
7. Executar testes selecionados (Health → Smoke → Load → Stress → Spike → Soak)
8. Upload de relatórios como artifacts
9. Resumo no Step Summary do GitHub
```

### Como Disparar

Este pipeline usa `workflow_dispatch` — precisa ser disparado manualmente:

1. Vá em **Actions** no GitHub
2. Selecione **"Pipeline - Standalone (npm)"**
3. Clique em **"Run workflow"**
4. Marque quais testes quer executar
5. Clique em **"Run workflow"**

### Quando Usar

- Testes rápidos sem overhead de Kubernetes
- Validação de scripts k6 antes de rodar no cluster
- Comparação de performance: "como performa sem K8s?"

---

## 8. Pipeline Kubernetes (kind)

**Arquivo**: `.github/workflows/pipeline-kubernetes.yml`

A pipeline completa. Cria um cluster Kubernetes, faz deploy da aplicação com autoscaling, executa os testes e coleta métricas do cluster em tempo real.

### Fluxo Detalhado (21 steps)

```
┌─────────────────────────────────────────────────┐
│ 1. SETUP DO CLUSTER                             │
│                                                 │
│  ① Checkout código                              │
│  ② Criar cluster kind (single-node CI)          │
│  ③ Verificar cluster (kubectl cluster-info)     │
│  ④ Instalar metrics-server (necessário pro HPA) │
├─────────────────────────────────────────────────┤
│ 2. DEPLOY DA APLICAÇÃO                          │
│                                                 │
│  ⑤ Deploy ServeRest (namespace, configmap,      │
│     deployment, service, hpa)                   │
│  ⑥ Aplicar HPA otimizado para CI (max 4)       │
│  ⑦ Aguardar pods ficarem ready                  │
│  ⑧ Configurar acesso via NodePort               │
├─────────────────────────────────────────────────┤
│ 3. COLETA DE MÉTRICAS                           │
│                                                 │
│  ⑨ Iniciar coletor de métricas (background)     │
│     → CSV a cada 15s: CPU, memória, réplicas    │
├─────────────────────────────────────────────────┤
│ 4. TESTES DE CARGA                              │
│                                                 │
│  ⑩ Setup k6                                     │
│  ⑪ Health Check                                 │
│  ⑫ Smoke Test                                   │
│  ⑬ Load Test                                    │
│  ⑭ Stress Test                                  │
│  ⑮ Spike Test                                   │
│  ⑯ Soak Test                                    │
├─────────────────────────────────────────────────┤
│ 5. PÓS-TESTES                                   │
│                                                 │
│  ⑰ Parar coleta de métricas                     │
│  ⑱ Verificar estado do cluster                  │
│  ⑲ Gerar dashboard visual (Plotly)              │
│  ⑳ Upload de relatórios e dashboards            │
│  ㉑ Resumo dos resultados                        │
└─────────────────────────────────────────────────┘
```

### NodePort vs Port-Forward

O acesso à API no cluster kind usa **NodePort** (porta 30000 mapeada do container Docker para o host). Isso é mais robusto que `kubectl port-forward`, que pode morrer sob carga pesada (300+ VUs).

```
GitHub Actions Runner (host)
    │
    │ http://localhost:30000
    ▼
Docker Container (kind node)
    │
    │ NodePort 30000 → Service porta 3000
    ▼
Pod ServeRest (porta 3000)
```

### Coleta de Métricas em Tempo Real

Um loop bash roda em background durante todos os testes, coletando a cada 15 segundos:

| Métrica | Fonte | Descrição |
|---------|-------|-----------|
| `hpa_cpu_pct` | HPA status | % de CPU reportada pelo HPA |
| `hpa_mem_pct` | HPA status | % de memória reportada pelo HPA |
| `current_replicas` | HPA status | Réplicas atuais |
| `desired_replicas` | HPA status | Réplicas desejadas pelo HPA |
| `pod_count` | kubectl get pods | Pods em execução |
| `total_cpu_millicores` | kubectl top pods | CPU total consumida |
| `total_mem_mib` | kubectl top pods | Memória total consumida |

Estes dados são salvos em `cluster-metrics.csv` e usados para gerar os dashboards.

---

## 9. Scripts k6 em Detalhe

### 9.1 Health Check (`00-health-check.js`)

```javascript
// 1 VU, 10 segundos
// Apenas GET / e verifica status 200
export default function () {
  const response = http.get(BASE_URL);
  check(response, {
    'status é 200': (r) => r.status === 200,
    'resposta contém ServeRest': (r) => r.body && r.body.includes('ServeRest'),
  });
}
```

**Thresholds**: p95 < 200ms, taxa de erro < 1%

### 9.2 Smoke Test (`01-smoke-test.js`)

```javascript
// 1 VU, stages progressivos
// Grupo 1: Health Check (GET /)
// Grupo 2: Listar recursos (GET /usuarios + GET /produtos)
```

**Thresholds**: p95 < 300ms, checks > 95%

### 9.3 Load Test (`02-load-test.js`)

O teste mais completo. Simula uma jornada real de usuário:

```javascript
// Stages: 0→10→20→0 VUs
// Grupo 1: Registro e Autenticação
//   - Criar usuário (POST /usuarios)
//   - Fazer login (POST /login)
// Grupo 2: Navegação de Produtos
//   - Listar produtos (GET /produtos)
//   - Buscar produto aleatório (GET /produtos/:id)
// Grupo 3: Criação de Produto
//   - Criar produto (POST /produtos) com token
```

**Dados únicos por iteração**: Cada VU cria emails e nomes únicos usando `__VU` (ID do VU) + `__ITER` (número da iteração) + `Date.now()`.

**Thresholds**: p95 < 800ms, p99 < 1500ms, checks > 95%

### 9.4 Stress Test (`03-stress-test.js`)

```javascript
// Stages: 10→50→100→200→300→0 VUs
// Cenário simplificado (criar usuario + login + listar)
// Try-catch para resiliência
// Métricas customizadas: custom_errors
```

**Thresholds**: p95 < 2000ms, taxa de erro < 5%, checks > 85%

Note os thresholds mais relaxados — em stress test, degradação é esperada.

### 9.5 Spike Test (`04-spike-test.js`)

```javascript
// Stages: 10→100(spike!)→10→100(spike!)→10→0
// Apenas operações de leitura (GET)
// Métrica customizada: spike_success_rate
```

**Thresholds**: p95 < 3000ms, taxa de erro < 10%, sucesso > 80%

Thresholds ainda mais relaxados — durante um spike, alguma degradação é aceitável. O importante é que o sistema se recupere.

### 9.6 Soak Test (`05-soak-test.js`)

```javascript
// Stages: ramp-up 5m → constante 30m → ramp-down 5m (20 VUs)
// Fluxo completo: registro → login → listar → criar produto
// Métricas customizadas: custom_response_time, business_errors
```

**Thresholds**: p95 < 1000ms, taxa de erro < 2%, checks > 95%

O soak test monitora se o tempo de resposta **degrada ao longo do tempo**. Se a latência sobe progressivamente, pode indicar memory leak ou esgotamento de recursos.

---

## 10. Kubernetes e Autoscaling (HPA)

### Como o HPA Funciona

O Horizontal Pod Autoscaler monitora métricas dos pods e ajusta o número de réplicas automaticamente.

```
                     ┌──────────────┐
                     │ metrics-server│
                     └──────┬───────┘
                            │ coleta métricas
          ┌─────────────────┼─────────────────┐
          ▼                 ▼                 ▼
     ┌────────┐       ┌────────┐       ┌────────┐
     │ Pod 1  │       │ Pod 2  │       │ Pod 3  │
     │ CPU:80%│       │ CPU:75%│       │ (novo) │
     └────────┘       └────────┘       └────────┘
          ▲                                 ▲
          │                                 │
          │         ┌──────────┐            │
          └─────────│   HPA    │────────────┘
                    │CPU>50%?  │
                    │Escalar!  │
                    └──────────┘
```

**Fórmula do HPA**:
```
réplicas_desejadas = ceil(réplicas_atuais × (métrica_atual / métrica_alvo))
```

Exemplo: 2 pods com CPU média de 80%, alvo é 50%:
```
réplicas = ceil(2 × (80 / 50)) = ceil(3.2) = 4
```

### Configuração do HPA neste projeto

| Parâmetro | Produção | CI |
|-----------|----------|----|
| minReplicas | 2 | 2 |
| maxReplicas | **10** | **4** |
| CPU target | 50% | 50% |
| Memória target | 80% | 80% |

**Por que max 4 no CI?** O runner do GitHub Actions tem recursos limitados (2 vCPUs, 7GB RAM). Mais de 4 pods causaria contenção de recursos no próprio node.

### Resource Requests e Limits

Cada pod do ServeRest tem:

```yaml
resources:
  requests:       # Mínimo garantido
    cpu: 100m     # 100 milicores = 0.1 CPU
    memory: 200Mi # 200 MiB de RAM
  limits:         # Máximo permitido
    cpu: 500m     # 500 milicores = 0.5 CPU
    memory: 512Mi # 512 MiB de RAM
```

**Importante**: O HPA usa o `requests.cpu` como base para o cálculo de percentual. Se o pod usa 250m de CPU e o request é 100m, o HPA vê 250% de utilização.

### Probes (Health Checks do Kubernetes)

O Deployment configura três tipos de probe:

- **startupProbe**: Verifica se o container iniciou (falha 12 vezes antes de reiniciar)
- **livenessProbe**: Verifica se o container está vivo (reinicia se falhar 3 vezes)
- **readinessProbe**: Verifica se o container pode receber tráfego

Todas fazem `GET /` na porta 3000.

### Comportamento de Scaling

**Scale Up (aumentar pods)**:
- `stabilizationWindowSeconds: 0` — reage imediatamente
- Pode dobrar (100%) ou adicionar até 4 pods a cada 30s
- Escolhe a política **mais agressiva** (selectPolicy: Max)

**Scale Down (diminuir pods)**:
- `stabilizationWindowSeconds: 60` — espera 60s de estabilidade
- Remove no máximo 50% ou 2 pods a cada 60s
- Escolhe a política **mais conservadora** (selectPolicy: Min)

**Por que assimétrico?** Subir rápido protege contra degradação. Descer devagar evita "yo-yo scaling" (subir e descer repetidamente).

---

## 11. Como Analisar os Resultados

### 11.1 Saída do k6 no terminal

Após cada teste, o k6 imprime um resumo como:

```
     checks.........................: 100.00% ✓ 4066  ✗ 0
     data_received..................: 3.2 MB  13 kB/s
     data_sent......................: 1.1 MB  4.5 kB/s
     http_req_duration..............: avg=2.46ms  min=0.95ms  med=2.08ms  max=22.23ms  p(90)=3.89ms  p(95)=4.25ms
     http_req_failed................: 0.00%   ✓ 0     ✗ 1693
     http_reqs......................: 1693    6.85/s
```

**Como ler**:
- `checks: 100%` → Todas as validações passaram
- `http_req_duration p(95)=4.25ms` → 95% das requisições completaram em menos de 4.25ms
- `http_req_failed: 0.00%` → Nenhuma requisição falhou
- `http_reqs: 6.85/s` → ~7 requisições por segundo

### 11.2 Thresholds (Passou ou Falhou?)

O k6 mostra ✓ ou ✗ ao lado de cada threshold:

```
     ✓ http_req_duration............: p(95)<800ms   p(95)=4.25ms
     ✓ http_req_failed..............: rate<0.01     rate=0.00
     ✓ checks......................: rate>0.95     rate=1.00
```

Se algum threshold falhar (✗), o k6 retorna exit code 99, e o step do pipeline fica vermelho.

### 11.3 O que procurar em cada tipo de teste

| Teste | Olhar para... | Sinal de problema |
|-------|--------------|-------------------|
| **Smoke** | Erros, checks falhando | Qualquer falha = bug funcional |
| **Load** | p95 latência, throughput | p95 > 800ms, throughput baixo |
| **Stress** | Ponto de degradação, recovery | Erros > 5%, não recupera |
| **Spike** | Tempo de recuperação | Erros persistem após spike |
| **Soak** | Tendência de latência | Latência crescente = memory leak |

### 11.4 Comparando Resultados

Para avaliar se o sistema está saudável, compare:

| Métrica | Bom | Aceitável | Ruim |
|---------|-----|-----------|------|
| p95 latência | < 200ms | < 1000ms | > 2000ms |
| Taxa de erro | 0% | < 1% | > 5% |
| Checks | 100% | > 95% | < 85% |
| Throughput | Estável | Oscila | Cai sob carga |

---

## 12. Dashboards e Relatórios

O pipeline gera vários tipos de relatórios, todos disponíveis como **Artifacts** no GitHub Actions.

### 12.1 k6 Web Dashboard (HTML interativo)

Cada teste gera um dashboard HTML completo (`*-dashboard.html`) com:

- **Gráfico de VUs ao longo do tempo**
- **Latência por percentil** (p50, p90, p95, p99)
- **Throughput** (requisições/segundo)
- **Taxa de erro** ao longo do tempo
- **Checks** passando/falhando

Para abrir: baixe o artifact e abra o `.html` no navegador. É interativo — hover nos gráficos mostra valores exatos.

### 12.2 Dashboard de Scaling do Cluster (Plotly)

O `cluster-scaling-dashboard.html` mostra 6 painéis:

| Painel | O que mostra |
|--------|-------------|
| CPU HPA (%) | Utilização de CPU reportada pelo HPA vs threshold de 50% |
| Memória HPA (%) | Utilização de memória vs threshold de 80% |
| Réplicas (atual vs desejado) | Quantos pods estão rodando vs quantos o HPA quer |
| Pods em Execução | Contagem de pods running |
| CPU Total (millicores) | Consumo total de CPU de todos os pods |
| Memória Total (MiB) | Consumo total de memória de todos os pods |

**Tema dark** estilo Grafana, com zoom, pan e hover interativos.

### 12.3 Relatórios JSON

- `*-summary.json`: Dados completos do k6 (todas as métricas)
- `*-analysis.json`: Resumo executivo (total requests, latência, erros)
- `cluster-metrics.csv`: Dados brutos do cluster (para análise customizada)

### 12.4 Step Summary do GitHub

Na página do workflow run, o **Summary** mostra:

- Testes executados (tabela)
- Métricas de scaling a cada 15s (tabela completa)
- Estado final do cluster (HPA + pods)
- Eventos de scaling (se houve autoscaling)
- Links para download dos dashboards

### Como baixar os Artifacts

1. Abra o workflow run no GitHub Actions
2. Scroll até a seção **Artifacts**
3. Clique em **k6-kubernetes-reports** para baixar o ZIP
4. Extraia e abra os HTMLs no navegador

---

## 13. Resultados Reais do Pipeline

Estes são os resultados reais da execução bem-sucedida do pipeline (run #23327539608):

### Smoke Test

| Métrica | Valor |
|---------|-------|
| Requisições | 69 |
| RPS | 1.49/s |
| Latência média | 2.42ms |
| p95 | 5.86ms |
| p99 (max) | 7.04ms |
| Taxa de erro | **0%** |
| Checks | **100%** (115/115) |

**Análise**: Sistema funcionando perfeitamente sem carga. Latência excelente (< 10ms).

### Load Test

| Métrica | Valor |
|---------|-------|
| Requisições | 1.693 |
| RPS | 6.85/s |
| Latência média | 2.47ms |
| p95 | **4.26ms** |
| Max | 22.24ms |
| Taxa de erro | **0%** |
| Checks | **100%** (4.066/4.066) |

**Análise**: Sob carga normal (10-20 VUs), o sistema performa muito bem. p95 de 4ms é excelente. O fluxo completo (registro → login → produtos) funciona sem problemas.

### Stress Test

| Métrica | Valor |
|---------|-------|
| Requisições | **64.232** |
| RPS | **193.83/s** |
| Latência média | 170.67ms |
| p95 | **937.59ms** |
| Max | 3.721ms (3.7s) |
| Taxa de erro | **0%** |
| Checks | **100%** (128.464/128.464) |

**Análise**: Mesmo com 300 VUs, **zero erros**! A latência subiu significativamente (p95 quase 1 segundo), mas o sistema se manteve estável. O HPA provavelmente escalou pods adicionais para absorver a carga.

### Spike Test

| Métrica | Valor |
|---------|-------|
| Requisições | **13.071** |
| RPS | 92.98/s |
| Latência média | 74.43ms |
| p95 | **361.59ms** |
| Max | 873.99ms |
| Taxa de erro | **0%** |
| Checks | **100%** (36.924/36.924) |
| Spike Success Rate | **100%** |

**Análise**: Os picos de 10→100 VUs foram absorvidos perfeitamente. A latência máxima ficou abaixo de 1 segundo mesmo durante os spikes. O sistema se recuperou completamente entre os picos.

### Resumo Geral

| Teste | Reqs | RPS | p95 | Erros | Status |
|-------|------|-----|-----|-------|--------|
| Smoke | 69 | 1.49 | 5.86ms | 0% | ✅ |
| Load | 1.693 | 6.85 | 4.26ms | 0% | ✅ |
| Stress | 64.232 | 193.83 | 937.59ms | 0% | ✅ |
| Spike | 13.071 | 92.98 | 361.59ms | 0% | ✅ |

**Todos os testes passaram com 0% de erro e 100% de checks.**

---

## 14. Problemas Comuns e Soluções

### "connection refused" no k6

**Causa**: O servidor não está acessível na URL configurada.

**Soluções**:
- Verificar se o ServeRest está rodando: `curl http://localhost:30000`
- No pipeline K8s: verificar se o NodePort está mapeado no kind-config
- Localmente: verificar se o port-forward está ativo

### "GoError: the body is null" no k6

**Causa**: Requisição falhou (connection refused/timeout) e o script tenta fazer `.json()` num body null.

**Solução**: Os scripts já têm null guards (`r.status !== 0 && r.json(...)`) para evitar isso.

### HPA não escala

**Causa**: metrics-server não está instalado ou não está pronto.

**Soluções**:
- Verificar: `kubectl get pods -n kube-system | grep metrics`
- O metrics-server pode levar 1-2 minutos para começar a reportar métricas
- Verificar se o Deployment tem `resources.requests` definidos (obrigatório para HPA)

### Testes muito lentos no CI

**Causa**: Usando stages de execução local no pipeline.

**Solução**: A env `K6_CI=true` já ativa stages mais curtos. Verificar se está definida no workflow.

### Cluster kind não cria

**Causa**: Docker não está rodando ou sem recursos suficientes.

**Soluções**:
- Verificar Docker: `docker info`
- Mínimo: 2 CPUs e 4GB RAM alocados para Docker
- No CI, o runner tem 2 vCPUs e 7GB RAM — suficiente para single-node

---

## 15. Glossário

| Termo | Definição |
|-------|-----------|
| **VU** | Virtual User — um usuário simulado pelo k6 |
| **RPS** | Requests Per Second — taxa de requisições por segundo |
| **p95/p99** | Percentil 95/99 — 95%/99% das requisições são mais rápidas que esse valor |
| **Threshold** | Critério de sucesso/falha definido no script k6 |
| **Stage** | Fase do teste com duração e número de VUs definidos |
| **HPA** | Horizontal Pod Autoscaler — escala pods automaticamente |
| **Pod** | Menor unidade do Kubernetes (1 ou mais containers) |
| **Deployment** | Recurso K8s que gerencia réplicas de pods |
| **Service** | Recurso K8s que expõe pods (load balancer interno) |
| **NodePort** | Tipo de Service que expõe uma porta no node |
| **kind** | Kubernetes in Docker — clusters locais para desenvolvimento/CI |
| **Ramp up** | Fase de aumento gradual de carga |
| **Ramp down** | Fase de diminuição gradual de carga |
| **Throughput** | Volume de dados/requisições processadas por unidade de tempo |
| **Latência** | Tempo entre enviar uma requisição e receber a resposta |
| **Check** | Validação customizada no k6 (ex: "status é 200") |
| **Artifact** | Arquivo gerado durante o pipeline, disponível para download |
| **metrics-server** | Componente K8s que coleta métricas de CPU/memória dos pods |
| **millicores** | Unidade de CPU no Kubernetes (1000m = 1 CPU core) |
| **MiB** | Mebibytes — unidade de memória (1 MiB = 1.048.576 bytes) |
| **CI/CD** | Continuous Integration / Continuous Delivery |
| **workflow_dispatch** | Gatilho manual de workflow no GitHub Actions |

---

## 16. Referências

### Documentação Oficial
- [k6 Documentation](https://k6.io/docs/) — Referência completa do k6
- [Kubernetes HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) — Como o HPA funciona
- [kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/) — Criar clusters locais
- [GitHub Actions](https://docs.github.com/en/actions) — Documentação de workflows
- [ServeRest](https://serverest.dev/) — API usada como alvo dos testes

### Conceitos
- [Tipos de teste de carga (k6)](https://k6.io/docs/test-types/) — Explicação oficial
- [Performance Testing Guidance](https://k6.io/docs/testing-guides/api-load-testing/) — Guia de boas práticas
- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) — Requests, limits e HPA

### Repositório do Projeto
- [Fork do ServeRest](https://github.com/magnonta/server-rest) — Branch `curso-devops`
- Pipeline Kubernetes: `.github/workflows/pipeline-kubernetes.yml`
- Pipeline Standalone: `.github/workflows/pipeline-standalone.yml`
- Scripts k6: `k6/scripts/`
- Manifests K8s: `k8s/serverest/`

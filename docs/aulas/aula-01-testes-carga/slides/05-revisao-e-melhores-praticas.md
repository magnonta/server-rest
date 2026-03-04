# Aula 01 - Testes de Carga em Pipelines CI/CD

## Parte 5: Revisão e Melhores Práticas

**Duração**: 30 minutos  
**Objetivo**: Consolidar aprendizado e compartilhar melhores práticas

---

## Agenda

1. Recapitulação do dia
2. Melhores práticas
3. Armadilhas comuns
4. Casos de uso reais
5. Próximos passos
6. Q&A final

---

## Recapitulação: Nossa Jornada Hoje

### Parte 1: Introdução aos Testes de Carga
- ✅ O que são e por que importam
- ✅ Tipos: Smoke, Load, Stress, Spike, Soak
- ✅ Métricas: p95, throughput, error rate
- ✅ Quando e onde aplicar

### Parte 2: Kubernetes e kind
- ✅ Conceitos básicos (Pod, Deployment, Service, HPA)
- ✅ Criar cluster local com kind
- ✅ Deploy de aplicação
- ✅ Auto-scaling configurado

---

## Recapitulação: Nossa Jornada Hoje

### Parte 3: Testes de Carga com k6
- ✅ Anatomia de teste k6
- ✅ VUs, stages, checks, thresholds
- ✅ Escrever múltiplos tipos de testes
- ✅ Analisar resultados
- ✅ Correlacionar com HPA

### Parte 4: CI/CD
- ✅ GitHub Actions workflow completo
- ✅ Automatizar testes no pipeline
- ✅ Gerar reports
- ✅ Comentar em Pull Requests
- ✅ Branch protection

---

## Arquitetura Completa que Construímos

```
┌──────────────────────────────────────────────────┐
│         GitHub Actions (CI/CD Runner)            │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │      kind (Kubernetes Local Cluster)       │ │
│  │                                            │ │
│  │  ┌──────────────────────────────────────┐ │ │
│  │  │  Metrics Server                      │ │ │
│  │  └──────────────────────────────────────┘ │ │
│  │                                            │ │
│  │  ┌──────────────────────────────────────┐ │ │
│  │  │  ServeRest Deployment                │ │ │
│  │  │  - Min 2 pods, Max 10 pods           │ │ │
│  │  │  - CPU requests: 100m                │ │ │
│  │  │  - HPA target: 50% CPU               │ │ │
│  │  └──────────────────────────────────────┘ │ │
│  │                                            │ │
│  │  ┌──────────────────────────────────────┐ │ │
│  │  │  Service (NodePort 30000)            │ │ │
│  │  └──────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────┘ │
│                     ↑                            │
│                     │                            │
│  ┌──────────────────────────────────────────┐   │
│  │  k6 Load Tests                           │   │
│  │  - Health Check → Smoke → Load → Stress │   │
│  │  - Thresholds validation                 │   │
│  │  - Metrics collection                    │   │
│  └──────────────────────────────────────────┘   │
│                     ↓                            │
│  ┌──────────────────────────────────────────┐   │
│  │  Results & Artifacts                     │   │
│  │  - JSON metrics                          │   │
│  │  - Summary report                        │   │
│  │  - PR comment                            │   │
│  └──────────────────────────────────────────┘   │
└──────────────────────────────────────────────────┘
```

---

## Melhores Práticas: Testes de Carga

### 1. Sempre Comece com Smoke Test

**❌ Errado**:
```bash
# Pular direto para stress test
k6 run stress-test.js
```

**✅ Correto**:
```bash
# Validar primeiro
k6 run smoke-test.js
k6 run load-test.js
k6 run stress-test.js
```

**Por quê**: Não adianta testar 1000 VUs se 1 VU já está falhando!

---

## Melhores Práticas: Testes de Carga

### 2. Use Percentis, Não Médias

**❌ Evitar**:
```javascript
// Threshold apenas em média
thresholds: {
  http_req_duration: ['avg<500']
}
```

**✅ Preferir**:
```javascript
// Thresholds em percentis
thresholds: {
  http_req_duration: [
    'p(95)<500',   // 95% dos usuários
    'p(99)<1000'   // 99% dos usuários
  ]
}
```

**Por quê**: Média esconde outliers!

---

## Melhores Práticas: Testes de Carga

### 3. Simule Comportamento Real

**❌ Irreal**:
```javascript
export default function() {
  // Loop infinito sem pausa
  http.get('/api/usuarios');
}
```

**✅ Realista**:
```javascript
export default function() {
  // Simular jornada de usuário
  http.get('/api/usuarios');
  sleep(randomBetween(1, 3));
  
  http.get('/api/produtos');
  sleep(randomBetween(2, 5));
  
  http.post('/api/carrinhos', payload);
  sleep(1);
}
```

---

## Melhores Práticas: Testes de Carga

### 4. Defina Thresholds Objetivos

**❌ Sem critério**:
```javascript
export const options = {
  vus: 10,
  duration: '30s'
  // Sem thresholds
};
```

**✅ Com critério**:
```javascript
export const options = {
  vus: 10,
  duration: '30s',
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
    checks: ['rate>0.95']
  }
};
```

**Por quê**: Sem threshold, você decide manualmente (inconsistente)

---

## Melhores Práticas: Testes de Carga

### 5. Versione Testes como Código

**✅ Estrutura Recomendada**:
```
k6/
├── modules/
│   ├── config.js          # Configurações compartilhadas
│   ├── helpers.js         # Funções utilitárias
│   └── api-client.js      # Abstração da API
├── scripts/
│   ├── smoke-test.js
│   ├── load-test.js
│   └── stress-test.js
└── data/
    └── test-data.json     # Dados de teste
```

---

## Melhores Práticas: Kubernetes

### 1. Sempre Defina Resources

**❌ Sem resources**:
```yaml
containers:
- name: app
  image: myapp:latest
  # Sem requests/limits
```

**✅ Com resources**:
```yaml
containers:
- name: app
  image: myapp:latest
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 256Mi
```

**Por quê**: HPA precisa de requests. Limits evitam um pod consumir tudo.

---

## Melhores Práticas: Kubernetes

### 2. Configure HPA Adequadamente

**❌ Valores arbitrários**:
```yaml
minReplicas: 1
maxReplicas: 100
targetCPUUtilizationPercentage: 80
```

**✅ Valores planejados**:
```yaml
minReplicas: 2      # Sempre redundância
maxReplicas: 10     # Baseado em capacidade
targetCPUUtilizationPercentage: 50  # Margem para picos
```

**Por quê**: 
- Min = 1 não tem redundância
- Max muito alto pode sobrecarregar cluster
- Target muito alto não deixa margem

---

## Melhores Práticas: Kubernetes

### 3. Use Namespaces para Isolamento

**❌ Tudo no default**:
```bash
kubectl apply -f deployment.yaml
# Vai para namespace default
```

**✅ Namespaces dedicados**:
```bash
kubectl create namespace serverest
kubectl apply -f deployment.yaml -n serverest
```

**Por quê**: Isolamento, organização, segurança

---

## Melhores Práticas: CI/CD

### 1. Fail Fast

**✅ Ordem Correta**:
```yaml
steps:
  - name: Smoke test (1 min)
  - name: Unit tests (2 min)
  - name: Load test (10 min)
  - name: Security scan (15 min)
```

**Por quê**: Detectar problemas rápido (feedback loop curto)

---

## Melhores Práticas: CI/CD

### 2. Salve Artefatos Importantes

**❌ Sem evidências**:
```yaml
- name: Run tests
  run: k6 run test.js
# Resultados perdidos
```

**✅ Com artefatos**:
```yaml
- name: Run tests
  run: k6 run --out json=results.json test.js

- name: Upload results
  uses: actions/upload-artifact@v4
  with:
    name: k6-results
    path: results.json
```

---

## Melhores Práticas: CI/CD

### 3. Tenha Timeouts

**❌ Sem timeout**:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    # Pode rodar para sempre
```

**✅ Com timeout**:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 30
```

**Por quê**: Evitar workflows travados consumindo recursos

---

## Armadilhas Comuns

### 1. Testar em Ambiente Inadequado

**❌ Problema**:
```
Testar em:
- Laptop pessoal com 4GB RAM
- WiFi instável
- Outros processos rodando
```

**✅ Solução**:
```
Testar em:
- CI/CD (ambiente controlado)
- Máquina dedicada
- Rede estável
```

---

## Armadilhas Comuns

### 2. Ignorar Warm-up

**❌ Problema**:
```javascript
export const options = {
  stages: [
    { duration: '10s', target: 100 }  // 0 → 100 muito rápido
  ]
};
```

**✅ Solução**:
```javascript
export const options = {
  stages: [
    { duration: '2m', target: 100 },   // Rampa gradual
    { duration: '5m', target: 100 }    // Mantém
  ]
};
```

**Por quê**: Aplicação precisa de tempo para warm-up (JIT, cache, etc.)

---

## Armadilhas Comuns

### 3. Não Monitorar Recursos

**❌ Problema**:
```
Executar teste e só olhar para métricas do k6
```

**✅ Solução**:
```bash
# Terminal 1: k6
k6 run test.js

# Terminal 2: Monitorar pods
kubectl top pods -n serverest

# Terminal 3: Monitorar nodes
kubectl top nodes
```

**Por quê**: Precisa entender ONDE está o gargalo

---

## Armadilhas Comuns

### 4. Usar Dados Fake

**❌ Problema**:
```javascript
// Testar com 10 produtos
// Produção tem 1 milhão de produtos
```

**✅ Solução**:
```javascript
// Importar dados realistas
import { SharedArray } from 'k6/data';

const produtos = new SharedArray('produtos', function() {
  return JSON.parse(open('./1million-produtos.json'));
});
```

**Por quê**: Volume de dados afeta performance drasticamente

---

## Armadilhas Comuns

### 5. Não Documentar Resultados

**❌ Problema**:
```
Executar testes mas não registrar resultados
→ Impossível comparar ao longo do tempo
```

**✅ Solução**:
```markdown
# Performance Baseline

## 2024-01-20 (v1.0)
- p95: 450ms
- Throughput: 1200 RPS
- Max VUs tested: 100

## 2024-02-15 (v1.1 - após otimização)
- p95: 320ms ✅ (-28%)
- Throughput: 1500 RPS ✅ (+25%)
- Max VUs tested: 150
```

---

## Casos de Uso Reais

### E-commerce na Black Friday

**Cenário**: Tráfego normal = 1000 VUs, Black Friday = 10000 VUs

**Preparação**:
1. Load test com 1000 VUs (baseline)
2. Stress test até 5000 VUs (encontrar limite)
3. Spike test simulando pico (10000 VUs por 5min)
4. Soak test com 3000 VUs por 6h (detectar leaks)
5. Configurar HPA para escalar até capacidade necessária

**Resultado**: Black Friday sem incidentes!

---

## Casos de Uso Reais

### API Bancária - Dia de Pagamento

**Cenário**: Último dia útil do mês (pico de transações)

**Desafio**: 
- Transações críticas (não podem falhar)
- Pico previsível mas extremo

**Solução**:
1. Load test com padrão histórico
2. Configurar auto-scaling agressivo (min=10, target=40%)
3. Pre-warming: Escalar antes do pico
4. Monitoramento em tempo real
5. Testes semanais para evitar regressão

---

## Casos de Uso Reais

### Streaming - Lançamento de Série

**Cenário**: Estreia de série popular

**Desafio**:
- Pico súbito no horário de lançamento
- Download de conteúdo (alto tráfego de rede)

**Solução**:
1. Spike test simulando horário de lançamento
2. CDN configurado
3. HPA baseado em múltiplas métricas (CPU + rede)
4. Cache agressivo
5. Testes incluindo download de chunks de vídeo

---

## Evolução da Performance

### Como Melhorar ao Longo do Tempo

**Ciclo de Melhoria Contínua**:

```
1. Medir (Baseline)
   ↓
2. Identificar gargalos
   ↓
3. Otimizar
   ↓
4. Medir novamente
   ↓
5. Comparar
   ↓
6. Documentar
   ↓
[Repeat]
```

---

## Ferramentas Complementares

### Monitoramento em Produção

**APM (Application Performance Monitoring)**:
- New Relic
- Datadog
- Dynatrace
- AppDynamics

**Observabilidade**:
- Prometheus + Grafana
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Jaeger (tracing distribuído)

**Alertas**:
- PagerDuty
- Opsgenie
- Slack/Discord webhooks

---

## Próximos Passos: Aprofundamento

### Nível Intermediário

1. **Testes distribuídos**: k6 em múltiplos runners
2. **Custom metrics**: Criar métricas de negócio
3. **Data-driven tests**: Parametrizar com CSV/JSON
4. **Browser testing**: k6 browser module
5. **Integração com Grafana Cloud**: Visualizações avançadas

---

## Próximos Passos: Aprofundamento

### Nível Avançado

1. **Chaos Engineering**: Combinar com Chaos Mesh
2. **Multi-region testing**: Testar latência global
3. **Production testing**: Shadow traffic, canary releases
4. **Cost optimization**: Testar diferentes configurações HPA
5. **ML para previsão**: Usar histórico para prever necessidade

---

## Certificações Relacionadas

### Kubernetes

- **CKA** (Certified Kubernetes Administrator)
- **CKAD** (Certified Kubernetes Application Developer)
- **CKS** (Certified Kubernetes Security Specialist)

### Cloud

- **AWS Solutions Architect**
- **Azure Administrator**
- **GCP Professional Cloud Architect**

---

## Livros Recomendados

### Performance Testing

- "The Art of Application Performance Testing" - Ian Molyneaux
- "Performance Testing Guidance for Web Applications" - Microsoft
- "Load Testing with k6" - Docs oficiais (online)

### Kubernetes

- "Kubernetes in Action" - Marko Lukša
- "Kubernetes Patterns" - Bilgin Ibryam
- "Production Kubernetes" - Josh Rosso

---

## Comunidades

### Onde Continuar Aprendendo

**Discord/Slack**:
- k6 Community Slack
- Kubernetes Slack
- DevOps Brasil

**Fóruns**:
- Stack Overflow (tags: k6, kubernetes, performance-testing)
- Reddit: r/kubernetes, r/devops

**YouTube**:
- k6 Office Hours
- CNCF (Cloud Native Computing Foundation)
- DevOps Toolkit

---

## Contribua com Open Source

### Projetos para Contribuir

**Iniciantes**:
- Documentação do k6
- Exemplos de testes
- Traduções

**Intermediários**:
- Grafana k6 (issues "good first issue")
- kind (ferramenta)
- Exemplos de workflows GitHub Actions

**Avançados**:
- k6 core (Go)
- Kubernetes (Go)
- Metrics Server

---

## Checklist de Conclusão

### Você Agora Sabe:

✅ Diferenciar tipos de testes de performance  
✅ Configurar cluster Kubernetes local  
✅ Escrever testes k6 completos  
✅ Configurar auto-scaling (HPA)  
✅ Criar pipeline CI/CD completo  
✅ Analisar resultados e identificar gargalos  
✅ Automatizar validações de performance  
✅ Gerar reports automáticos  

**Parabéns! 🎉**

---

## Desafio Final (Opcional)

### Projeto Completo

**Tarefa**: Implementar tudo que aprendemos em um projeto pessoal

**Requisitos**:
1. API própria (Node.js, Python, Go, etc.)
2. Dockerfile
3. Manifests Kubernetes
4. Mínimo 3 testes k6 (smoke, load, stress)
5. GitHub Actions workflow completo
6. README com resultados

**Prazo**: Até próxima aula (1 semana)

**Bônus**: Compartilhar no LinkedIn/GitHub!

---

## Avaliação do Professor

### Como Será Avaliado

**Critérios** (Aula 01 + Aula 02):

- **Participação** (20%): Presença e engajamento
- **Exercícios práticos** (40%): Completar exercícios em aula
- **Pipeline funcionando** (30%): Workflow executando com sucesso
- **Desafio final** (10%): Projeto pessoal (opcional)

**Mínimo para aprovação**: 70%

---

## Feedback da Turma

### Queremos Ouvir Você!

**Responda (anônimo)**:
1. Conteúdo foi claro? (1-5)
2. Ritmo foi adequado? (1-5)
3. Exercícios foram úteis? (1-5)
4. O que mais gostou?
5. O que poderia melhorar?
6. Sugestões para próxima aula?

**Link**: [formulário]

---

## Próxima Aula: Preview

### Aula 02 - Testes de Segurança em Pipelines CI/CD

**Tópicos Principais**:
1. **Tipos de testes de segurança** (SAST, DAST, SCA)
2. **Trivy**: Scanner de vulnerabilidades para containers
3. **OWASP ZAP**: Testes de segurança em APIs
4. **npm audit**: Vulnerabilidades em dependências
5. **Pipeline completo** de segurança no GitHub Actions

---

## Próxima Aula: O que Trazer

### Preparação

✅ **Mesmas ferramentas** de hoje (Docker, kind, kubectl)  
✅ **Cluster funcionando** (pode usar o de hoje)  
✅ **GitHub** configurado  
✅ **Dúvidas** anotadas da Aula 01  

**Material novo**:
- Trivy (instalaremos juntos)
- OWASP ZAP Docker image (faremos pull)

---

## Durante a Semana

### Recursos de Suporte

**Dúvidas?**
- Email: [professor@email.com]
- Discord: [link do servidor]
- Office hours: Terça 19h-20h (online)

**Material**:
- Repositório: github.com/ServeRest/ServeRest
- Guias: /docs/aulas/
- Cheatsheets: Impressos ou em /docs/

---

## Agradecimentos Especiais

### Contribuidores

**ServeRest API**: Paulo Gonçalves (@PauloGoncalvesBH)  
**k6**: Grafana Labs  
**kind**: Kubernetes SIG Testing  
**Kubernetes**: CNCF Community  

**E você**: Por dedicar seu sábado ao aprendizado! 🙌

---

## Últimas Palavras

### Reflexão

> "Performance é uma funcionalidade. Se você não testa, não funciona."
> 
> — Alguém sábio na internet

**Lembre-se**:
- Testes de carga não são luxo, são necessidade
- Automatização economiza tempo e dinheiro
- Pequenos problemas em dev são grandes problemas em produção
- Comece simples, evolua gradualmente

---

## Foto da Turma! 📸

### Vamos Registrar

**Compartilhe no LinkedIn**:
- Marque o professor
- Use hashtags: #DevOps #QA #Kubernetes #k6 #LoadTesting
- Marque a universidade

**Rede de contatos**: Conectem-se entre vocês!

---

## Até a Próxima!

### Nos Vemos Próximo Sábado

**Horário**: 8h - 12h  
**Local**: [sala]  
**Tema**: Segurança em Pipelines CI/CD

**Descanse bem!**  
**Pratique durante a semana!**  
**Compartilhe o que aprendeu!**

---

## Q&A Aberto

### Perguntas Finais

**Formato**: Levante a mão ou chat

**Qualquer tópico**:
- Conceitos da aula
- Carreira em DevOps/QA
- Ferramentas
- Mercado de trabalho
- Certificações
- Próxima aula

---

# Notas para o Professor

## Timing Sugerido (30 minutos)

- Slides 1-10: Recapitulação (5 min)
- Slides 11-30: Melhores práticas e armadilhas (10 min)
- Slides 31-45: Casos de uso e próximos passos (8 min)
- Slides 46-55: Avaliação e feedback (5 min)
- Slides 56-58: Q&A (até completar 30 min)

## Objetivos desta Seção

1. **Consolidar**: Revisar tudo que foi visto
2. **Contextualizar**: Mostrar aplicação real
3. **Motivar**: Inspirar continuação do aprendizado
4. **Coletar feedback**: Melhorar próximas aulas

## Dicas de Apresentação

- **Seja entusiasta**: É a conclusão, celebre o aprendizado!
- **Seja honesto**: Reconheça se algo não ficou claro
- **Seja acessível**: Deixe claro que está disponível para dúvidas
- **Seja inspirador**: Mostre que isso é só o começo

## Após a Aula

- Enviar email com resumo e links
- Disponibilizar slides e material
- Criar grupo WhatsApp/Discord se ainda não existe
- Responder dúvidas que surgirem durante a semana
- Preparar Aula 02 baseado no feedback

## Material para Enviar por Email

```
Assunto: Aula 01 - Material e Próximos Passos

Olá turma!

Obrigado pela participação hoje! Segue material da aula:

📂 Repositório: [link]
📊 Slides: [link Google Slides]
📝 Exercícios: [link]
🎯 Desafio opcional: [link]

Office hours: Terça 19h [link meet]

Nos vemos sábado para Aula 02 - Segurança!

Abs,
[Nome]
```

# Aula 01 - Testes de Carga em Pipelines CI/CD

## Parte 3: Testes de Carga com k6

**Duração**: 60 minutos  
**Objetivo**: Escrever e executar testes de carga com k6

---

## Agenda

1. Introdução ao k6
2. Anatomia de um teste k6
3. Executando testes localmente
4. Tipos de testes (Smoke, Load, Stress)
5. Analisando resultados
6. Observando auto-scaling

---

## O que é k6?

**Definição**: Ferramenta moderna de teste de carga orientada a desenvolvedores.

**Criado por**: Grafana Labs (mesma empresa do Grafana)

**Linguagem**: JavaScript (ES6+)

**Filosofia**: 
- Testes como código
- CI/CD friendly
- Performance primeiro
- Developer experience

---

## Por que k6? (Revisão)

### Vantagens Principais

✅ **JavaScript**: Linguagem que você já conhece  
✅ **CLI-first**: Perfeito para automação  
✅ **Métricas ricas**: p90, p95, p99, etc.  
✅ **Checks**: Assertions durante o teste  
✅ **Thresholds**: Critérios de pass/fail  
✅ **Modular**: Reutilização de código  
✅ **Local ou Cloud**: Flexível  
✅ **Open Source**: Gratuito

---

## k6 vs Outras Ferramentas

### Comparação Rápida

```
JMeter:   GUI → XML → Difícil versionar
k6:       Código JS → Git → Fácil CI/CD

Locust:   Python → Ótimo, mas menos métricas
k6:       JavaScript → Métricas riquíssimas

Artillery: YAML → Simples mas limitado
k6:       JS → Simples E poderoso
```

**k6 é o melhor dos mundos**: Simplicidade + Poder

---

## Instalação do k6

### Windows (Chocolatey)

```powershell
choco install k6
```

### Mac (Homebrew)

```bash
brew install k6
```

### Linux

```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

### Validar

```bash
k6 version
```

---

## Anatomia de um Teste k6

### Estrutura Básica

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

// 1️⃣ Configuração
export const options = {
  vus: 10,        // Virtual Users
  duration: '30s' // Duração
};

// 2️⃣ Função principal (executa para cada VU)
export default function() {
  // 3️⃣ Fazer requisição
  const res = http.get('http://localhost:30000/');
  
  // 4️⃣ Validar resposta
  check(res, {
    'status é 200': (r) => r.status === 200
  });
  
  // 5️⃣ Esperar (simular tempo entre requisições)
  sleep(1);
}
```

---

## Entendendo VUs (Virtual Users)

**O que é VU?**  
Usuário virtual que executa o teste em loop.

**Como funciona**:
```
VU 1: GET /usuarios → check → sleep → repeat
VU 2: GET /usuarios → check → sleep → repeat
VU 3: GET /usuarios → check → sleep → repeat
...
```

**Exemplo**: 10 VUs por 30s
- Cada VU faz ~30 requisições (1 req/s com sleep de 1s)
- Total: ~300 requisições

---

## Options: Configurando o Teste

### Opções Básicas

```javascript
export const options = {
  vus: 10,           // Usuários virtuais
  duration: '30s',   // Duração total
  
  // OU usar stages (rampa)
  stages: [
    { duration: '10s', target: 10 },  // Subir de 0 para 10 VUs em 10s
    { duration: '30s', target: 10 },  // Manter 10 VUs por 30s
    { duration: '10s', target: 0 }    // Descer para 0 em 10s
  ]
};
```

**stages** = Cenários mais realistas (rampa gradual)

---

## Checks: Validações

### Assertions Durante o Teste

```javascript
import { check } from 'k6';

const res = http.get('http://localhost:30000/usuarios');

check(res, {
  'status é 200': (r) => r.status === 200,
  'resposta < 500ms': (r) => r.timings.duration < 500,
  'tem usuarios': (r) => JSON.parse(r.body).usuarios.length > 0
});
```

**Importante**: Checks **não** param o teste. São apenas contadores.

---

## Thresholds: Critérios de Sucesso

### Pass/Fail Automático

```javascript
export const options = {
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% das req < 500ms
    http_req_failed: ['rate<0.01'],    // Taxa de erro < 1%
    checks: ['rate>0.95']              // 95% dos checks passam
  }
};
```

**Diferença de Checks**:
- **Checks**: Informam (não falham o teste)
- **Thresholds**: Determinam pass/fail do teste

---

## Sleep: Simular Comportamento Real

### Por que Sleep?

**Sem sleep**:
```javascript
export default function() {
  http.get('/usuarios'); // Executa imediatamente
}
// Resultado: Loop infinito, máximo de requisições
```

**Com sleep**:
```javascript
export default function() {
  http.get('/usuarios');
  sleep(1); // Espera 1 segundo
}
// Resultado: 1 requisição por segundo por VU (mais realista)
```

**Usuários reais** não fazem requisições instantaneamente!

---

## Módulos k6 Úteis

### Importações Comuns

```javascript
// HTTP
import http from 'k6/http';

// Utilidades
import { check, sleep, group } from 'k6';

// Métricas customizadas
import { Trend, Counter, Rate } from 'k6/metrics';

// Dados
import { SharedArray } from 'k6/data';

// Navegador (avançado)
import { browser } from 'k6/experimental/browser';
```

---

## Nosso Primeiro Teste: Health Check

### Arquivo: `k6/scripts/00-health-check.js`

```javascript
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 1,
  duration: '10s'
};

export default function() {
  const res = http.get('http://localhost:30000/');
  
  check(res, {
    'status é 200': (r) => r.status === 200,
    'tem mensagem': (r) => r.body.includes('ServeRest')
  });
}
```

**Objetivo**: Verificar se API está respondendo

---

## Executando o Teste

### Comando

```bash
k6 run k6/scripts/00-health-check.js
```

**Output esperado**:
```
     ✓ status é 200
     ✓ tem mensagem

     checks.........................: 100.00%
     data_received..................: 15 kB
     data_sent......................: 2.3 kB
     http_req_duration..............: avg=45ms p(95)=67ms
     http_reqs......................: 10
     vus............................: 1
```

---

## Entendendo as Métricas

### Principais Outputs

**http_req_duration**: Tempo de resposta
- `avg`: Média
- `min`: Mínimo
- `med`: Mediana (p50)
- `max`: Máximo
- `p(90)`, `p(95)`, `p(99)`: Percentis

**http_reqs**: Total de requisições

**http_req_failed**: Taxa de falhas

**checks**: % de checks que passaram

---

## Percentis Explicados

### Por que p95 é importante?

**Exemplo**: 100 requisições

```
99 requisições: 100ms
1 requisição: 5000ms (timeout)

Média: 149ms (não representa a realidade!)
p95: 100ms (95% dos usuários tiveram essa exp)
p99: 5000ms (1% teve problema)
```

**Lição**: Média esconde problemas. Use percentis!

---

## Smoke Test

### Arquivo: `k6/scripts/01-smoke-test.js`

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 1,
  duration: '1m',
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01']
  }
};

export default function() {
  // Testar vários endpoints
  const baseUrl = 'http://localhost:30000';
  
  // GET /
  let res = http.get(baseUrl);
  check(res, { 'GET / OK': (r) => r.status === 200 });
  
  sleep(1);
  
  // GET /usuarios
  res = http.get(`${baseUrl}/usuarios`);
  check(res, { 'GET /usuarios OK': (r) => r.status === 200 });
  
  sleep(1);
}
```

---

## Load Test

### Arquivo: `k6/scripts/02-load-test.js`

```javascript
export const options = {
  stages: [
    { duration: '2m', target: 10 },   // Subir para 10 VUs
    { duration: '5m', target: 10 },   // Manter 10 VUs
    { duration: '2m', target: 20 },   // Subir para 20 VUs
    { duration: '5m', target: 20 },   // Manter 20 VUs
    { duration: '2m', target: 0 }     // Descer para 0
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
    checks: ['rate>0.95']
  }
};

export default function() {
  // Simular fluxo de usuário
  const baseUrl = 'http://localhost:30000';
  
  // 1. Listar usuários
  http.get(`${baseUrl}/usuarios`);
  sleep(1);
  
  // 2. Listar produtos
  http.get(`${baseUrl}/produtos`);
  sleep(1);
  
  // 3. Buscar produto específico
  http.get(`${baseUrl}/produtos?_limit=1`);
  sleep(2);
}
```

---

## Stress Test

### Arquivo: `k6/scripts/03-stress-test.js`

```javascript
export const options = {
  stages: [
    { duration: '2m', target: 50 },    // Subir para 50
    { duration: '5m', target: 50 },    // Manter
    { duration: '2m', target: 100 },   // Dobrar
    { duration: '5m', target: 100 },   // Manter
    { duration: '2m', target: 200 },   // Dobrar
    { duration: '5m', target: 200 },   // Manter até quebrar
    { duration: '2m', target: 0 }      // Recuperação
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000'],
    http_req_failed: ['rate<0.05']  // Aceita 5% erro (stress!)
  }
};
```

**Objetivo**: Encontrar limite do sistema

---

## Spike Test

### Arquivo: `k6/scripts/04-spike-test.js`

```javascript
export const options = {
  stages: [
    { duration: '10s', target: 10 },    // Normal
    { duration: '1m', target: 10 },     // Estável
    { duration: '10s', target: 300 },   // SPIKE!
    { duration: '3m', target: 300 },    // Mantém spike
    { duration: '10s', target: 10 },    // Volta ao normal
    { duration: '3m', target: 10 },     // Recuperação
    { duration: '10s', target: 0 }      // Finaliza
  ]
};
```

**Objetivo**: Testar recuperação após pico súbito

---

## Soak Test

### Arquivo: `k6/scripts/05-soak-test.js`

```javascript
export const options = {
  stages: [
    { duration: '2m', target: 20 },     // Subir
    { duration: '30m', target: 20 },    // Manter MUITO tempo
    { duration: '2m', target: 0 }       // Descer
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01']
  }
};
```

**Objetivo**: Detectar memory leaks, degradação ao longo do tempo

---

## Organizando Testes: Módulos

### Arquivo: `k6/modules/config.js`

```javascript
export const BASE_URL = __ENV.BASE_URL || 'http://localhost:30000';

export const STAGES = {
  smoke: [
    { duration: '1m', target: 1 }
  ],
  load: [
    { duration: '2m', target: 10 },
    { duration: '5m', target: 10 },
    { duration: '2m', target: 0 }
  ],
  stress: [
    { duration: '2m', target: 50 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 0 }
  ]
};
```

**Vantagem**: Reutilizar configurações

---

## Organizando Testes: Helpers

### Arquivo: `k6/modules/serverest-api.js`

```javascript
import http from 'k6/http';
import { check } from 'k6';

const BASE_URL = 'http://localhost:30000';

export function getUsuarios() {
  const res = http.get(`${BASE_URL}/usuarios`);
  check(res, {
    'getUsuarios: status 200': (r) => r.status === 200
  });
  return res;
}

export function getProdutos() {
  const res = http.get(`${BASE_URL}/produtos`);
  check(res, {
    'getProdutos: status 200': (r) => r.status === 200
  });
  return res;
}
```

---

## Usando Módulos

### Teste Simplificado

```javascript
import { getUsuarios, getProdutos } from '../modules/serverest-api.js';
import { STAGES } from '../modules/config.js';
import { sleep } from 'k6';

export const options = {
  stages: STAGES.load
};

export default function() {
  getUsuarios();
  sleep(1);
  
  getProdutos();
  sleep(1);
}
```

**Benefício**: Código limpo, reutilizável, testável

---

## Executando Todos os Testes

### Sequência Recomendada

```bash
# 1. Health check
k6 run k6/scripts/00-health-check.js

# 2. Smoke test
k6 run k6/scripts/01-smoke-test.js

# 3. Load test
k6 run k6/scripts/02-load-test.js

# 4. Stress test (opcional)
k6 run k6/scripts/03-stress-test.js
```

**Sempre nesta ordem!** Não adianta stress test se smoke falhou.

---

## Analisando Resultados

### Métricas Críticas

**1. http_req_duration (p95)**
```
✅ p(95)=450ms  → Excelente
⚠️  p(95)=850ms  → Atenção
❌ p(95)=2500ms → Problema
```

**2. http_req_failed**
```
✅ rate=0%      → Perfeito
⚠️  rate=0.5%   → Investigar
❌ rate=5%      → Crítico
```

---

## Analisando Resultados

### Métricas Críticas (cont.)

**3. checks**
```
✅ rate=100%    → Todos passaram
⚠️  rate=95%    → Alguns falharam
❌ rate=80%     → Muitos problemas
```

**4. http_reqs**
```
Mostra throughput (requisições/segundo)
Comparar com SLA: "Sistema deve suportar 1000 RPS"
```

---

## Observando Auto-scaling

### Monitoramento Durante Teste

**Terminal 1**: Executar teste
```bash
k6 run k6/scripts/02-load-test.js
```

**Terminal 2**: Monitorar HPA
```bash
kubectl get hpa -n serverest -w
```

**Terminal 3**: Monitorar pods
```bash
kubectl get pods -n serverest -w
```

---

## O que Esperar no Auto-scaling

### Sequência de Eventos

```
1. Teste inicia (10 VUs)
   → CPU dos pods começa a subir

2. CPU passa de 50%
   → HPA detecta (leva ~15-30s)

3. HPA cria mais pods
   → REPLICAS: 2 → 3 → 4

4. Novos pods ficam Ready
   → Carga se distribui

5. CPU volta para < 50%
   → Sistema estabiliza

6. Teste termina
   → HPA remove pods extras (leva ~5min)
```

---

## Métricas do HPA

### Interpretando Output

```bash
kubectl get hpa -n serverest

NAME            REFERENCE            TARGETS    MINPODS   MAXPODS   REPLICAS
serverest-hpa   Deployment/serverest 75%/50%    2         10        4
```

**Leitura**:
- CPU atual: **75%**
- Target: **50%**
- CPU > target → **Escalar!**
- Pods atuais: **4**
- Pode criar até: **10**

---

## Correlacionando k6 e HPA

### Análise Conjunta

**k6 mostra**:
- http_req_duration subindo
- Throughput estável ou caindo

**HPA mostra**:
- CPU subindo
- Criando mais pods

**Conclusão**: Auto-scaling está funcionando!

**Validação**: 
- Após novos pods, tempo de resposta volta ao normal?
- Se sim: ✅ HPA efetivo
- Se não: ❌ Problema não é capacidade (investigar código/DB)

---

## Salvando Resultados

### Output em JSON

```bash
k6 run --out json=results.json k6/scripts/02-load-test.js
```

### Output em CSV

```bash
k6 run --out csv=results.csv k6/scripts/02-load-test.js
```

### Output Customizado

```bash
k6 run \
  --out json=results.json \
  --summary-export=summary.json \
  k6/scripts/02-load-test.js
```

---

## Visualizando Resultados

### k6 Cloud (Opcional)

```bash
# Login
k6 login cloud

# Executar e enviar para cloud
k6 run --out cloud k6/scripts/02-load-test.js
```

**Benefícios**:
- Gráficos bonitos
- Histórico de testes
- Comparação entre execuções

**Custo**: Gratuito até 50 testes/mês

---

## Exercício Prático 1

### Seu Primeiro Teste

**Tarefa**: Criar teste que:
1. Faz GET em `/usuarios`
2. Valida status 200
3. Valida que retorna array
4. Usa 5 VUs por 30s
5. Define threshold: p95 < 500ms

**Tempo**: 10 minutos

**Arquivo**: `exercicios/meu-primeiro-teste.js`

---

## Exercício Prático 2

### Load Test Personalizado

**Tarefa**: Criar teste com 3 stages:
1. Subir de 0 a 15 VUs em 1min
2. Manter 15 VUs por 3min
3. Descer para 0 em 1min

**Endpoints**: 
- 50% requisições para `/usuarios`
- 50% requisições para `/produtos`

**Tempo**: 15 minutos

---

## Exercício Prático 3

### Observar Auto-scaling

**Tarefa**:
1. Iniciar load test
2. Monitorar HPA em tempo real
3. Anotar:
   - Quando HPA escalou?
   - Quantos pods foram criados?
   - Tempo de resposta melhorou?
   - Quando HPA descalou?

**Tempo**: 20 minutos

---

## Dicas de Performance

### Otimizações k6

**❌ Evitar**:
```javascript
// Logs dentro do loop (muito lento)
console.log('Requisição feita');
```

**✅ Preferir**:
```javascript
// Métricas customizadas
import { Counter } from 'k6/metrics';
const myCounter = new Counter('my_counter');
myCounter.add(1);
```

---

## Dicas de Performance

### Otimizações k6 (cont.)

**❌ Evitar**:
```javascript
// Criar objetos complexos no loop
const payload = JSON.stringify({...});
```

**✅ Preferir**:
```javascript
// Criar fora do loop
const payload = JSON.stringify({...});

export default function() {
  http.post(url, payload);
}
```

---

## Troubleshooting Comum

### Problema: "connection refused"

```
ERRO: dial tcp: connection refused
```

**Solução**:
```bash
# Verificar se API está rodando
curl http://localhost:30000/

# Verificar service
kubectl get svc -n serverest

# Verificar pods
kubectl get pods -n serverest
```

---

## Troubleshooting Comum

### Problema: HPA não escala

```
HPA mostra TARGETS: <unknown>/50%
```

**Causa**: Metrics Server não está funcionando

**Solução**:
```bash
# Verificar metrics-server
kubectl get pods -n kube-system | grep metrics

# Testar métricas
kubectl top nodes

# Reinstalar se necessário
kubectl apply -f k8s/kind/metrics-server.yaml
```

---

## Troubleshooting Comum

### Problema: Teste muito lento

**Sintoma**: k6 demora muito para executar

**Causas possíveis**:
1. Muitos VUs para sua máquina
2. Muitos checks/logs
3. Sleep muito curto

**Solução**:
- Reduzir VUs
- Simplificar checks
- Aumentar sleep

---

## Boas Práticas k6

### Checklist

✅ Sempre começar com smoke test  
✅ Usar thresholds (critérios objetivos)  
✅ Usar percentis (p95, p99) em vez de média  
✅ Modularizar código (reutilização)  
✅ Versionar testes no Git  
✅ Documentar cenários de teste  
✅ Salvar resultados históricos  
✅ Validar após cada mudança de código  

---

## Próximos Passos

### O que Vem Agora

✅ Conceitos de k6  
✅ Anatomia de um teste  
✅ Tipos de testes escritos  
✅ Execução local  
✅ Análise de resultados  
✅ Observação de auto-scaling  

**Próximo**:
- ☕ Break 10 minutos
- 🤖 Integrar no GitHub Actions
- 🎯 Executar testes no CI/CD
- 📊 Analisar reports automatizados

---

## Resumo da Parte 3

### O que Aprendemos

✅ Estrutura de teste k6 (options, default function)  
✅ VUs, stages, duration  
✅ Checks vs Thresholds  
✅ Percentis (p95, p99)  
✅ 5 tipos de testes (smoke, load, stress, spike, soak)  
✅ Módulos e helpers  
✅ Análise de métricas  
✅ Correlação k6 + HPA  

---

## Recursos para Aprofundar

### Links Úteis

**k6 Docs**:
- https://k6.io/docs/
- https://k6.io/docs/using-k6/metrics/

**Exemplos**:
- https://github.com/grafana/k6-learn

**Comunidade**:
- https://community.k6.io/

---

## Quiz Rápido

### Teste Seus Conhecimentos

1. Qual a diferença entre check e threshold?
2. Por que usar p95 em vez de média?
3. Quando executar smoke test?
4. O que é VU?
5. Como forçar teste a falhar?

**Compartilhe suas respostas!**

---

## Dúvidas?

### Conceitos para Revisar

- VUs vs Requisições por segundo?
- Checks vs Thresholds?
- Quando usar cada tipo de teste?
- Como ler métricas k6?
- Por que sleep é importante?

---

# Notas para o Professor

## Timing Sugerido (60 minutos)

- Slides 1-20: Conceitos e anatomia (15 min)
- Slides 21-35: Tipos de testes (15 min)
- Slides 36-45: Execução e análise (15 min)
- Slides 46-55: Exercícios práticos (10 min)
- Slides 56-60: Q&A e troubleshooting (5 min)

## Demonstrações Recomendadas

1. **Executar health-check ao vivo**: Mostrar output completo
2. **Executar load-test**: Mostrar em um terminal
3. **Monitorar HPA**: Mostrar em terminal paralelo
4. **Analisar métricas**: Explicar cada linha do output

## Exercícios - Sugestões

- **Exercício 1**: Fazer junto com os alunos (código na tela)
- **Exercício 2**: Alunos fazem sozinhos, depois mostrar solução
- **Exercício 3**: Fazer em duplas, compartilhar resultados

## Material de Apoio

- Ter testes prontos em arquivo para copiar/colar
- Terminal com fonte grande
- Janelas lado a lado (k6 + kubectl)

## Checkpoint

Antes de avançar para CI/CD:
- ✅ Todos executaram pelo menos 1 teste com sucesso
- ✅ Todos viram HPA escalar
- ✅ Todos entendem output do k6

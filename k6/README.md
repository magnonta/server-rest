# Scripts k6 de Load Testing

Esta pasta contém todos os scripts de teste de carga usando k6 para a API ServeRest.

## 📁 Estrutura

```
k6/
├── scripts/           # Scripts de teste
├── modules/           # Módulos reutilizáveis
├── data/             # Dados de teste
├── scenarios/        # Cenários complexos
└── results/          # Resultados dos testes (gitignored)
```

## 🧪 Tipos de Testes

### 00-health-check.js
**Teste básico de saúde**
- 1 VU por 10 segundos
- Verifica se API está respondendo
- Uso: Antes de qualquer teste mais complexo

```bash
k6 run k6/scripts/00-health-check.js
```

### 01-smoke-test.js
**Teste de fumaça - Validação básica**
- 1 VU por ~1.5 minutos
- Verifica funcionalidades principais
- Deve passar sempre antes de outros testes

```bash
k6 run k6/scripts/01-smoke-test.js
```

### 02-load-test.js
**Teste de carga - Uso normal**
- Simula carga esperada em produção
- 0 → 10 → 20 VUs
- Duração: ~9 minutos
- Testa criação de usuários, produtos, autenticação

```bash
k6 run k6/scripts/02-load-test.js
```

### 03-stress-test.js
**Teste de estresse - Encontrar limites**
- Aumenta carga progressivamente
- 10 → 50 → 100 → 200 → 300 VUs
- Duração: ~11 minutos
- Objetivo: Encontrar ponto de quebra

```bash
k6 run k6/scripts/03-stress-test.js
```

### 04-spike-test.js
**Teste de pico - Carga súbita**
- Simula picos repentinos (Black Friday, etc)
- Alterna entre 10 e 100 VUs
- Duração: ~5 minutos
- Valida comportamento em situações extremas

```bash
k6 run k6/scripts/04-spike-test.js
```

### 05-soak-test.js
**Teste de resistência - Longa duração**
- Mantém carga constante por muito tempo
- 20 VUs por 30 minutos
- Duração: ~40 minutos
- Detecta memory leaks e degradação

```bash
k6 run k6/scripts/05-soak-test.js
```

## 📊 Métricas Importantes

### Métricas Padrão do k6

| Métrica | Descrição | Objetivo |
|---------|-----------|----------|
| `http_req_duration` | Tempo de resposta das requisições | p95 < 500ms |
| `http_req_failed` | Taxa de requisições falhadas | < 1% |
| `http_reqs` | Total de requisições | - |
| `vus` | Usuários virtuais ativos | - |
| `iterations` | Iterações completadas | - |
| `checks` | Validações passadas | > 95% |

### Como Ler os Resultados

```
✓ http_req_duration..............: avg=234.5ms  min=45ms   med=198ms  max=1.2s   p(90)=412ms  p(95)=589ms
✓ http_req_failed................: 0.23%   ✓ 12     ✗ 5188
✓ checks.........................: 97.45%  ✓ 5055   ✗ 132
```

- ✓ = Threshold passou
- ✗ = Threshold falhou
- `avg` = Média
- `p(95)` = 95% das requisições foram mais rápidas que este valor
- `p(99)` = 99% das requisições foram mais rápidas que este valor

## 🎯 Thresholds (Critérios de Sucesso)

Thresholds padrão definidos em `modules/config.js`:

```javascript
{
  'http_req_duration': ['p(95)<500'],           // 95% < 500ms
  'http_req_failed': ['rate<0.01'],            // < 1% de erro
  'checks': ['rate>0.95'],                     // > 95% checks OK
}
```

Cada teste pode sobrescrever estes valores conforme necessidade.

## 🚀 Executando os Testes

### Teste Individual

```bash
# Executar um teste específico
k6 run k6/scripts/02-load-test.js

# Com variável de ambiente customizada
k6 run --env BASE_URL=http://localhost:3000 k6/scripts/02-load-test.js

# Com mais VUs (sobrescreve config do script)
k6 run --vus 50 --duration 5m k6/scripts/02-load-test.js
```

### Todos os Testes (Sequencial)

```bash
# Executar script auxiliar
./scripts/load-testing/run-all-tests.sh
```

### Com Kubernetes Rodando

```bash
# 1. Garantir que cluster está rodando
kubectl get pods -n serverest

# 2. Executar teste
k6 run k6/scripts/02-load-test.js

# 3. Em outro terminal, observar HPA
watch kubectl get hpa -n serverest

# 4. Observar pods escalando
watch kubectl get pods -n serverest
```

## 📈 Visualizando Resultados

### Relatório HTML

Os testes automaticamente geram relatórios HTML em `k6/results/`:

```bash
# Abrir relatório no navegador
open k6/results/load-test-summary.html
```

### Métricas em Tempo Real

Durante execução, k6 mostra métricas no terminal:

```
running (0m30.0s), 15/20 VUs, 234 complete and 0 interrupted iterations

     ✓ status é 200
     ✓ produto criado com sucesso

     checks.........................: 98.72% ✓ 461    ✗ 6
     data_received..................: 2.1 MB 70 kB/s
     data_sent......................: 1.4 MB 47 kB/s
     http_req_duration..............: avg=245ms min=34ms med=198ms max=1.1s p(90)=423ms p(95)=612ms
```

### Grafana + InfluxDB (Opcional)

Para visualização avançada, integre com Grafana:

```bash
# Executar com output para InfluxDB
k6 run --out influxdb=http://localhost:8086/k6 k6/scripts/02-load-test.js
```

## 🔧 Módulos Reutilizáveis

### modules/config.js
Configurações globais:
- `BASE_URL`: URL da API
- `DEFAULT_THRESHOLDS`: Thresholds padrão
- `*_STAGES`: Configurações de stages para cada tipo de teste

### modules/serverest-api.js
Funções para interagir com ServeRest:
- `criarUsuario()`
- `fazerLogin()`
- `listarProdutos()`
- `criarProduto()`
- `criarCarrinho()`
- `concluirCompra()`
- `thinkTime()`: Simula tempo de pensamento do usuário

## 💡 Boas Práticas

### 1. Sempre começar com Smoke Test
```bash
k6 run k6/scripts/01-smoke-test.js
```
Se smoke falhar, não adianta executar load/stress.

### 2. Entender o Objetivo
- **Smoke**: Funciona?
- **Load**: Aguenta uso normal?
- **Stress**: Onde quebra?
- **Spike**: Aguenta picos?
- **Soak**: Degrada ao longo do tempo?

### 3. Executar em Sequência
```
Smoke → Load → Stress → Spike → Soak
```

### 4. Analisar Resultados
Não apenas olhar se passou/falhou, mas:
- Onde estão os gargalos?
- Quais endpoints são mais lentos?
- Há memory leaks?
- Sistema se recupera de picos?

### 5. Comparar com Baseline
Sempre tenha um baseline de comparação:
```bash
# Executar e salvar baseline
k6 run k6/scripts/02-load-test.js > baseline.txt

# Comparar com execução atual
k6 run k6/scripts/02-load-test.js > current.txt
diff baseline.txt current.txt
```

## ⚠️ Cuidados

### Não Executar em Produção!
- Testes de carga podem derrubar servidor
- Execute apenas em ambientes de teste/staging
- Para ServeRest online (serverest.dev), NÃO execute stress/spike

### Resources Adequados
- Certifique-se que cluster tem recursos suficientes
- kind: mínimo 4GB RAM, 2 CPUs
- Monitore uso de recursos durante testes

### Limpeza de Dados
Os testes criam muitos dados. Limpe periodicamente:
```bash
# Reiniciar deployment para limpar dados
kubectl rollout restart deployment/serverest -n serverest
```

## 🎓 Para Alunos

### Exercícios

1. **Modificar Thresholds**: Altere thresholds do load test e observe resultados
2. **Criar Novo Cenário**: Crie um teste que simule jornada completa de compra
3. **Customizar Stages**: Modifique stages para testar cenário específico
4. **Métricas Customizadas**: Adicione suas próprias métricas (Counter, Rate, Trend)
5. **Integração CI/CD**: Execute teste em GitHub Actions

### Desafios

- Criar teste que valide SLA de 95% das requisições < 300ms
- Implementar teste que detecte memory leak
- Configurar alertas baseados em thresholds
- Gerar relatório comparativo entre execuções

## 📚 Referências

- [k6 Documentation](https://k6.io/docs/)
- [k6 Best Practices](https://k6.io/docs/misc/fine-tuning-os/)
- [k6 Examples](https://k6.io/docs/examples/)
- [ServeRest API Docs](https://serverest.dev/)

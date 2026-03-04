# Aula 01 - Testes de Carga em Pipelines CI/CD

## Parte 1: Introdução aos Testes de Carga

**Curso**: Pós-Graduação em QA  
**Duração**: 50 minutos  
**Professor**: [Seu Nome]

---

## Agenda

1. O que são Testes de Carga?
2. Por que automatizar testes de carga?
3. Tipos de testes de performance
4. Métricas importantes
5. Quando e onde aplicar

---

## O que são Testes de Carga?

**Definição**: Testes que avaliam o comportamento de um sistema sob **carga esperada** ou **carga extrema**.

**Objetivo Principal**: 
- Garantir que a aplicação suporta o número esperado de usuários
- Identificar gargalos de performance
- Validar capacidade de escalabilidade
- Prevenir problemas em produção

---

## Por que são importantes?

### Cenários Reais

**Exemplo 1: E-commerce na Black Friday**
- Pico de 10x o tráfego normal
- Sem testes: site fora do ar, perda de vendas
- Com testes: sistema preparado, vendas garantidas

**Exemplo 2: Sistema bancário**
- Último dia útil do mês (pagamentos de salário)
- Sem testes: lentidão, timeout, reclamações
- Com testes: experiência fluida para milhões de usuários

---

## Custo de Problemas de Performance

### Impactos Mensuráveis

- **Financeiro**: 1 hora de indisponibilidade pode custar milhões
- **Reputação**: Clientes migram para concorrentes
- **Legal**: Multas por descumprimento de SLA
- **Operacional**: Time apagando incêndio 24/7

**Estatística**: 53% dos usuários abandonam sites que demoram mais de 3 segundos para carregar (Google, 2023)

---

## Por que AUTOMATIZAR Testes de Carga?

### Benefícios da Automação

✅ **Detecção Precoce**: Problemas encontrados antes de produção  
✅ **Custo Reduzido**: Consertar bug em dev = $100, em produção = $10.000  
✅ **Confiança**: Deploy sem medo  
✅ **Consistência**: Mesmos testes, sempre  
✅ **Velocidade**: Feedback em minutos, não dias  
✅ **Documentação**: Testes servem como especificação de performance

---

## Manual vs Automatizado

| Aspecto | Manual | Automatizado |
|---------|--------|--------------|
| **Tempo** | Dias/semanas | Minutos/horas |
| **Custo** | Alto (equipe dedicada) | Baixo (infraestrutura) |
| **Frequência** | Esporádico | A cada commit |
| **Consistência** | Variável | 100% reproduzível |
| **Cobertura** | Limitada | Ampla |
| **Feedback** | Lento | Imediato |

---

## Tipos de Testes de Performance

### 1. Smoke Test (Teste de Fumaça)
- **Carga**: Mínima (1-2 usuários)
- **Duração**: Curta (1-2 minutos)
- **Objetivo**: Verificar se o sistema está funcional
- **Quando**: Antes de qualquer outro teste
- **Exemplo**: "O sistema responde?"

---

## Tipos de Testes de Performance

### 2. Load Test (Teste de Carga)
- **Carga**: Esperada em produção
- **Duração**: Média (5-15 minutos)
- **Objetivo**: Validar comportamento sob carga normal
- **Quando**: A cada release
- **Exemplo**: "O sistema suporta 100 usuários simultâneos?"

---

## Tipos de Testes de Performance

### 3. Stress Test (Teste de Estresse)
- **Carga**: Além do esperado (gradual até quebrar)
- **Duração**: Variável (até encontrar limite)
- **Objetivo**: Descobrir ponto de quebra
- **Quando**: Planejamento de capacidade
- **Exemplo**: "Onde o sistema quebra? Em 500 ou 5000 usuários?"

---

## Tipos de Testes de Performance

### 4. Spike Test (Teste de Pico)
- **Carga**: Aumento súbito e extremo
- **Duração**: Curta com picos
- **Objetivo**: Validar resposta a picos repentinos
- **Quando**: Eventos especiais planejados
- **Exemplo**: "Sistema aguenta pico de Black Friday?"

---

## Tipos de Testes de Performance

### 5. Soak Test (Teste de Resistência)
- **Carga**: Constante e prolongada
- **Duração**: Longa (horas/dias)
- **Objetivo**: Detectar vazamento de memória
- **Quando**: Antes de releases grandes
- **Exemplo**: "Sistema permanece estável por 24h?"

---

## Comparação Visual dos Tipos

```
Smoke:    ▁ (verificação rápida)
Load:     ▂▃▄▄▄▃▂ (rampa suave)
Stress:   ▁▂▃▄▅▆▇█ (até quebrar)
Spike:    ▁▁█▁▁█▁ (picos súbitos)
Soak:     ▄▄▄▄▄▄▄ (constante por muito tempo)
```

---

## Métricas Importantes

### 1. Tempo de Resposta (Response Time)
- **O que é**: Tempo total desde requisição até resposta
- **Meta Típica**: < 200ms para APIs, < 2s para páginas
- **Importância**: Experiência do usuário

### 2. Throughput (Taxa de Transferência)
- **O que é**: Requisições processadas por segundo (RPS)
- **Meta Típica**: Depende do SLA (ex: 1000 RPS)
- **Importância**: Capacidade do sistema

---

## Métricas Importantes

### 3. Taxa de Erros (Error Rate)
- **O que é**: Percentual de requisições com erro
- **Meta Típica**: < 0.1% (1 em 1000)
- **Importância**: Confiabilidade

### 4. Percentis (p50, p95, p99)
- **O que é**: Tempo de resposta em diferentes percentis
- **Exemplo**: p95 = 500ms significa que 95% das requisições foram < 500ms
- **Importância**: Identificar outliers

---

## Métricas Importantes

### 5. Utilização de Recursos
- **CPU**: % de uso do processador
- **Memória**: Uso de RAM
- **Rede**: Largura de banda
- **I/O**: Disco

**Meta**: < 70% sob carga normal (margem para picos)

---

## Anatomia de uma Métrica Boa

### Exemplo Prático

**Ruim**: "O sistema está rápido"  
**Bom**: "p95 de tempo de resposta = 450ms com 100 usuários simultâneos e 0% de erro"

**Por quê?**
- ✅ Específico (450ms)
- ✅ Mensurável (p95)
- ✅ Contextualizado (100 usuários)
- ✅ Validado (0% erro)

---

## Quando Aplicar Testes de Carga?

### No Ciclo de Desenvolvimento

1. **Desenvolvimento Local**: Smoke tests
2. **Pull Request**: Smoke + Load tests
3. **Staging**: Load + Stress tests
4. **Pré-Produção**: Todos os tipos
5. **Produção**: Monitoramento contínuo

---

## Quando Aplicar Testes de Carga?

### Gatilhos para Execução

- ✅ Antes de cada release
- ✅ Após mudanças em APIs críticas
- ✅ Após mudanças em banco de dados
- ✅ Antes de eventos de alto tráfego
- ✅ Após incidentes de performance
- ✅ Regularmente (ex: semanalmente)

---

## Onde Executar Testes de Carga?

### Ambientes

**❌ NÃO execute em produção**  
Pode derrubar o sistema real!

**✅ Ambientes Adequados**:
1. **Local**: Desenvolvimento e debug
2. **CI/CD**: Validação automatizada
3. **Staging**: Testes realistas
4. **Ambiente Dedicado**: Testes de longa duração

---

## Onde Executar Testes de Carga?

### Infraestrutura

**Opção 1: Cloud Pública** (AWS, Azure, GCP)
- ✅ Escalável
- ✅ Sob demanda
- ❌ Custo variável

**Opção 2: Kubernetes** (nossa escolha hoje)
- ✅ Replicável
- ✅ Isolado
- ✅ Controlado

---

## Desafios Comuns

### Top 5 Problemas

1. **Ambiente não representativo**: Testes em máquina pequena
2. **Dados não realistas**: Teste com 10 registros, produção tem 10 milhões
3. **Testes isolados**: Não considera dependências externas
4. **Métricas erradas**: Focar apenas no tempo médio (ignorar p95)
5. **Falta de ação**: Fazer testes mas não corrigir problemas

---

## Boas Práticas

### Checklist para Sucesso

✅ **Defina metas claras**: "Sistema deve suportar 500 RPS com p95 < 500ms"  
✅ **Use dados realistas**: Volume e variedade  
✅ **Teste dependências**: Banco, cache, APIs externas  
✅ **Monitore recursos**: CPU, memória, rede  
✅ **Versione testes**: Testes de carga são código  
✅ **Documente resultados**: Histórico de performance  
✅ **Aja nos problemas**: Teste sem ação é desperdício

---

## Exemplo Real: ServeRest API

### Nossa API de Exemplo Hoje

**ServeRest**: API REST para testes de QA
- Endpoints: Usuários, Produtos, Carrinhos, Login
- Tecnologia: Node.js + Express
- Objetivo: Aprender testes de carga em API real

**Vamos testar**:
- Quantos usuários simultâneos suporta?
- Tempo de resposta sob carga?
- Onde está o gargalo?

---

## Ferramentas do Mercado

### Principais Opções

| Ferramenta | Tipo | Curva de Aprendizado | Custo |
|------------|------|----------------------|-------|
| **k6** ⭐ | Código (JS) | Média | Gratuito |
| JMeter | GUI | Alta | Gratuito |
| Gatling | Código (Scala) | Alta | Gratuito |
| Locust | Código (Python) | Baixa | Gratuito |
| Artillery | Código (YAML) | Baixa | Gratuito |
| LoadRunner | GUI | Alta | Pago |

**Hoje usaremos k6**: Moderno, fácil de integrar no CI/CD, ótima documentação

---

## Por que k6?

### Vantagens para QA

✅ **JavaScript**: Linguagem familiar  
✅ **CLI**: Fácil automação  
✅ **Métricas ricas**: p90, p95, p99 out-of-the-box  
✅ **Checks**: Validações durante o teste  
✅ **Thresholds**: Critérios de falha automáticos  
✅ **CI/CD friendly**: Fácil integração  
✅ **Documentação**: Excelente  
✅ **Comunidade**: Ativa

---

## Arquitetura da Aula de Hoje

```
┌─────────────────────────────────────────┐
│          GitHub Actions (CI/CD)          │
│  ┌───────────────────────────────────┐  │
│  │      Kind (Kubernetes Local)      │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │   ServeRest API (Pods)      │  │  │
│  │  │   + HPA (Auto-scaling)      │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
│              ↑                           │
│              │ k6 Load Tests             │
│  ┌───────────────────────────────────┐  │
│  │   Smoke → Load → Stress Tests     │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

---

## O que Faremos Hoje

### Jornada Prática (4 horas)

1. ✅ **Conceitos** (esta apresentação)
2. 🔧 **Setup**: Instalar ferramentas
3. 🐳 **Kubernetes**: Criar cluster local com kind
4. 📊 **k6**: Escrever e executar testes
5. 📈 **HPA**: Configurar auto-scaling
6. 🤖 **CI/CD**: Automatizar no GitHub Actions
7. 🎯 **Exercícios**: Praticar!

---

## Expectativas de Aprendizado

### Ao final desta aula, você será capaz de:

✅ Explicar tipos de testes de performance  
✅ Identificar métricas importantes  
✅ Criar cluster Kubernetes local com kind  
✅ Escrever testes de carga com k6  
✅ Configurar auto-scaling (HPA)  
✅ Integrar testes no GitHub Actions  
✅ Analisar resultados e identificar gargalos  

---

## Recursos de Apoio

### Material Disponível

📂 **Repositório**: github.com/ServeRest/ServeRest  
📖 **Guias**: `/docs/aulas/aula-01-testes-carga/guias/`  
📝 **Exercícios**: `/docs/aulas/aula-01-testes-carga/exercicios/`  
🔖 **Cheatsheets**: Comandos principais  
🆘 **Troubleshooting**: Problemas comuns

---

## Perguntas Frequentes

**P: Preciso saber Kubernetes para este curso?**  
R: Não! Vamos ensinar o básico necessário.

**P: Meu PC precisa ser potente?**  
R: Não. Kind roda em qualquer máquina moderna.

**P: E se eu travar?**  
R: Temos guias detalhados e estarei aqui para ajudar!

---

## Dicas para Aproveitar a Aula

1. 💻 **Mãos no teclado**: Acompanhe os exemplos
2. ❓ **Pergunte**: Não existe pergunta boba
3. 🐛 **Erre**: Erros são oportunidades de aprender
4. 🤝 **Colabore**: Ajude os colegas
5. 📝 **Anote**: Dúvidas e insights
6. ⏸️ **Pause**: Avise se estiver perdido

---

## Próximo Passo

### Break de 10 minutos

Depois:
- ✅ Verificar instalação das ferramentas
- 🚀 Criar nosso primeiro cluster Kubernetes
- 🎯 Executar primeiro teste de carga

**Prepare**:
- Máquina ligada
- Terminal aberto
- PowerShell como administrador (Windows)

---

## Obrigado!

### Dúvidas?

**Contato**: [seu-email@exemplo.com]  
**Material**: [link-do-repositorio]  
**Slides**: [link-google-slides]

---

# Notas para o Professor

## Timing Sugerido (50 minutos)

- Slides 1-10: Conceitos básicos (10 min)
- Slides 11-20: Tipos de testes (10 min)
- Slides 21-30: Métricas e boas práticas (10 min)
- Slides 31-40: Ferramentas e arquitetura (10 min)
- Slides 41-48: Logística e Q&A (10 min)

## Dicas de Apresentação

- **Use exemplos reais**: E-commerce, bancos, streaming
- **Seja interativo**: Pergunte "Quem já passou por lentidão em produção?"
- **Demonstre**: Se possível, mostre um teste real rodando
- **Contextualize**: Relacione com experiência de QA dos alunos
- **Encoraje**: Lembre que todos começaram do zero

## Material Extra

- Vídeos: Busque "k6 load testing tutorial" no YouTube
- Artigos: k6.io/docs tem excelentes guias
- Comparações: "k6 vs JMeter" para contexto

# Aula 01 - Testes de Carga em Pipelines CI/CD

## Parte 2: Introdução ao Kubernetes e Kind

**Duração**: 40 minutos  
**Objetivo**: Entender Kubernetes básico e criar cluster local com kind

---

## Agenda

1. O que é Kubernetes?
2. Por que Kubernetes para testes?
3. Conceitos básicos
4. O que é kind?
5. Criando cluster local
6. Deployando ServeRest

---

## O que é Kubernetes? (k8s)

**Definição Simples**: Sistema para automatizar deploy, escala e gerenciamento de aplicações em containers.

**Analogia**: 
- **Container** = Apartamento
- **Kubernetes** = Condomínio gerenciado
  - Distribui "apartamentos" (containers)
  - Gerencia recursos (energia, água)
  - Escala automaticamente
  - Substitui se algo quebrar

---

## Por que Kubernetes?

### Problemas que Resolve

**Sem Kubernetes**:
```
❌ Aplicação cai → Preciso reiniciar manualmente
❌ Tráfego aumenta → Preciso criar mais servidores
❌ Versão nova → Preciso atualizar um por um
❌ Servidor falha → Usuários ficam sem acesso
```

**Com Kubernetes**:
```
✅ Aplicação cai → Kubernetes reinicia automaticamente
✅ Tráfego aumenta → Kubernetes cria mais pods
✅ Versão nova → Rolling update automático
✅ Servidor falha → Pods migram para outro servidor
```

---

## Por que Kubernetes para Testes de Carga?

### Benefícios Específicos

1. **Ambiente Realista**: Mesma estrutura de produção
2. **Auto-scaling**: Testar HPA (Horizontal Pod Autoscaler)
3. **Isolamento**: Testes não afetam outros sistemas
4. **Reprodutibilidade**: Mesmo ambiente, sempre
5. **Custo Zero**: kind roda localmente
6. **Aprendizado**: Habilidade valiosa no mercado

---

## Conceitos Básicos do Kubernetes

### 1. Pod

**O que é**: Menor unidade do Kubernetes. Agrupa um ou mais containers.

**Analogia**: Um "apartamento" onde sua aplicação mora.

```
┌─────────────┐
│    Pod      │
│ ┌─────────┐ │
│ │Container│ │ ← Sua aplicação aqui
│ └─────────┘ │
└─────────────┘
```

**Importante**: Pods são efêmeros (podem ser criados/destruídos)

---

## Conceitos Básicos do Kubernetes

### 2. Deployment

**O que é**: Controlador que gerencia pods.

**Responsabilidades**:
- Garantir número de réplicas
- Fazer rolling updates
- Rollback se necessário

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: serverest
spec:
  replicas: 3  # ← Quero 3 pods
```

---

## Conceitos Básicos do Kubernetes

### 3. Service

**O que é**: Expõe pods na rede.

**Por quê**: Pods têm IPs efêmeros. Service fornece IP fixo.

**Analogia**: 
- **Pod** = Apartamento (número pode mudar)
- **Service** = Portaria do prédio (endereço fixo)

```
Internet → Service (IP fixo) → Pods (IPs variáveis)
```

---

## Conceitos Básicos do Kubernetes

### 4. Namespace

**O que é**: Isolamento lógico dentro do cluster.

**Analogia**: Diferentes "andares" no prédio.

```
Cluster Kubernetes
├── namespace: desenvolvimento (andar 1)
├── namespace: teste (andar 2)
└── namespace: producao (andar 3)
```

**Hoje usaremos**: `serverest` namespace

---

## Conceitos Básicos do Kubernetes

### 5. HPA (Horizontal Pod Autoscaler)

**O que é**: Escala pods automaticamente baseado em métricas.

**Exemplo**:
```yaml
minReplicas: 2    # Mínimo de pods
maxReplicas: 10   # Máximo de pods
targetCPU: 50%    # Escalar quando CPU > 50%
```

**Cenário**:
- Tráfego normal → 2 pods
- Tráfego aumenta → 5 pods
- Tráfego cai → Volta para 2 pods

---

## Arquitetura Kubernetes Simplificada

```
┌────────────────────────────────────────────┐
│           Cluster Kubernetes               │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │         Control Plane                │ │
│  │  (Cérebro - toma decisões)           │ │
│  └──────────────────────────────────────┘ │
│                                            │
│  ┌──────────────┐  ┌──────────────┐      │
│  │  Worker Node │  │  Worker Node │      │
│  │              │  │              │      │
│  │  ┌────┐┌────┐│  │  ┌────┐┌────┐│      │
│  │  │Pod ││Pod ││  │  │Pod ││Pod ││      │
│  │  └────┘└────┘│  │  └────┘└────┘│      │
│  └──────────────┘  └──────────────┘      │
└────────────────────────────────────────────┘
```

---

## O que é kind?

**kind** = **K**ubernetes **in** **D**ocker

**Definição**: Ferramenta para rodar clusters Kubernetes locais usando containers Docker.

**Criado por**: Time do Kubernetes (ferramenta oficial)

**Objetivo Original**: Testar o próprio Kubernetes

**Hoje usamos para**: Desenvolvimento e testes locais

---

## Por que kind?

### Comparação com Alternativas

| Ferramenta | Velocidade | Recursos | Multi-node | Windows |
|------------|------------|----------|------------|---------|
| **kind** ⭐ | ⚡⚡⚡ | Baixo | ✅ Sim | ✅ Sim |
| minikube | ⚡⚡ | Médio | ⚠️ Limitado | ✅ Sim |
| k3d | ⚡⚡⚡ | Baixo | ✅ Sim | ✅ Sim |
| Docker Desktop | ⚡ | Alto | ❌ Não | ✅ Sim |

**Nossa escolha**: kind - rápido, leve, multi-node, amplamente usado

---

## Vantagens do kind

### Por que amamos kind

✅ **Rápido**: Cluster em < 1 minuto  
✅ **Leve**: Apenas Docker necessário  
✅ **Multi-node**: Simula cluster real  
✅ **CI/CD friendly**: Usado em pipelines  
✅ **Gratuito**: 100% open source  
✅ **Documentação**: Excelente  
✅ **Comunidade**: Muito ativa  
✅ **Reproduzível**: Mesma configuração sempre

---

## Anatomia de um Cluster kind

### Nossa Configuração Hoje

```
kind-cluster
├── Control Plane (1 nó)
│   └── Gerencia o cluster
└── Worker Nodes (2 nós)
    ├── Worker 1 → Roda pods
    └── Worker 2 → Roda pods
```

**Total**: 3 containers Docker = 1 cluster Kubernetes completo!

---

## Configuração do kind

### Arquivo: kind-config.yaml

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  # Control plane
  - role: control-plane
  
  # Workers
  - role: worker
  - role: worker
```

**Resultado**: Cluster com 1 control-plane + 2 workers

---

## Componentes que Vamos Deployar

### Stack Completa

```
1. Metrics Server
   ↓ (fornece métricas de CPU/memória)
   
2. ServeRest Deployment
   ↓ (nossa API)
   
3. Service
   ↓ (expõe a API)
   
4. HPA
   ↓ (auto-scaling)
```

---

## Metrics Server

**O que é**: Componente que coleta métricas de recursos (CPU, memória).

**Por que precisamos**: HPA precisa de métricas para decidir quando escalar.

**Sem Metrics Server**:
```
HPA: "Preciso de métricas de CPU"
Cluster: "Não tenho métricas" 
HPA: "Então não posso escalar" ❌
```

**Com Metrics Server**:
```
HPA: "Preciso de métricas de CPU"
Metrics Server: "CPU está em 70%"
HPA: "Vou criar mais pods!" ✅
```

---

## Deployment do ServeRest

### Definição Simplificada

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: serverest
  namespace: serverest
spec:
  replicas: 2  # ← Iniciar com 2 pods
  template:
    spec:
      containers:
      - name: serverest
        image: serveRest/serveRest:latest
        resources:
          requests:
            cpu: 100m      # Mínimo necessário
            memory: 128Mi
          limits:
            cpu: 500m      # Máximo permitido
            memory: 256Mi
```

---

## Resources: Requests vs Limits

### Conceito Importante

**Requests** (Pedido):
- Mínimo garantido ao pod
- Usado pelo scheduler para decidir onde colocar o pod
- **Analogia**: "Preciso de pelo menos 1 cama"

**Limits** (Limite):
- Máximo que o pod pode usar
- Se ultrapassar, pod pode ser morto (OOMKilled)
- **Analogia**: "Não posso usar mais que 3 camas"

---

## Resources: Exemplo Prático

```yaml
resources:
  requests:
    cpu: 100m      # 0.1 CPU core garantido
    memory: 128Mi  # 128 MB garantido
  limits:
    cpu: 500m      # Máximo 0.5 CPU core
    memory: 256Mi  # Máximo 256 MB
```

**Interpretação**:
- Pod precisa de **pelo menos** 100m CPU e 128Mi RAM
- Pod pode usar **até** 500m CPU e 256Mi RAM
- HPA vai escalar baseado no uso em relação ao **request**

---

## Service: Expondo a API

### NodePort Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: serverest
  namespace: serverest
spec:
  type: NodePort
  selector:
    app: serverest
  ports:
  - port: 3000         # Porta interna
    targetPort: 3000   # Porta do container
    nodePort: 30000    # Porta externa
```

**Acesso**: `localhost:30000`

---

## HPA: Auto-scaling

### Configuração

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: serverest-hpa
  namespace: serverest
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: serverest
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

---

## HPA: Como Funciona

### Algoritmo Simplificado

```
1. Metrics Server coleta CPU atual de cada pod
2. HPA calcula média: (pod1_cpu + pod2_cpu) / 2
3. Se média > 50% (target):
   → Criar mais pods
4. Se média < 50%:
   → Remover pods (respeitando minReplicas)
```

**Exemplo**:
- 2 pods com CPU em 70% → HPA cria mais pods
- 5 pods com CPU em 20% → HPA remove pods até chegar em 2 (mínimo)

---

## Comandos kubectl Essenciais

### Gerenciamento Básico

```bash
# Ver pods
kubectl get pods -n serverest

# Ver detalhes do pod
kubectl describe pod <nome> -n serverest

# Ver logs
kubectl logs <nome-pod> -n serverest

# Ver HPA
kubectl get hpa -n serverest

# Acompanhar HPA em tempo real
kubectl get hpa -n serverest -w
```

---

## Comandos kubectl Essenciais

### Debugging

```bash
# Ver eventos (útil para debug)
kubectl get events -n serverest

# Executar comando dentro do pod
kubectl exec -it <nome-pod> -n serverest -- sh

# Ver métricas de recursos
kubectl top pods -n serverest
kubectl top nodes
```

---

## Workflow Completo

### Do Zero ao Deploy

```
1. Instalar Docker
   ↓
2. Instalar kind e kubectl
   ↓
3. Criar cluster com kind
   ↓
4. Instalar Metrics Server
   ↓
5. Criar namespace
   ↓
6. Aplicar Deployment
   ↓
7. Aplicar Service
   ↓
8. Aplicar HPA
   ↓
9. Validar com k6
```

---

## Demo ao Vivo

### Vamos Criar Nosso Cluster!

**Seguiremos o guia**:  
`/docs/aulas/aula-01-testes-carga/guias/02-configurando-cluster-kind.md`

**Passos**:
1. ✅ Verificar Docker rodando
2. 🚀 Criar cluster kind
3. 📊 Instalar Metrics Server
4. 🚢 Deploy ServeRest
5. 🎯 Validar funcionamento

---

## Checklist Pré-Demo

### Verificar Antes de Começar

```powershell
# Docker está rodando?
docker ps

# kind está instalado?
kind version

# kubectl está instalado?
kubectl version --client
```

**Tudo OK?** → Vamos criar o cluster!  
**Algum problema?** → Veja o guia de instalação

---

## Criando o Cluster

### Comando

```bash
cd k8s/kind
kind create cluster --name serverest-cluster --config kind-config.yaml
```

**O que acontece**:
1. kind baixa imagem do Kubernetes
2. Cria 3 containers Docker (1 control-plane + 2 workers)
3. Configura rede entre eles
4. Configura kubectl para apontar para o cluster

**Tempo**: ~1-2 minutos

---

## Validando o Cluster

### Verificações

```bash
# Cluster foi criado?
kind get clusters

# Nós estão prontos?
kubectl get nodes

# Deve mostrar:
# NAME                    STATUS   ROLE           AGE
# serverest-control-plane Ready    control-plane  1m
# serverest-worker        Ready    <none>         1m
# serverest-worker2       Ready    <none>         1m
```

**✅ Todos em "Ready"?** → Cluster funcionando!

---

## Instalando Metrics Server

### Comando

```bash
kubectl apply -f k8s/kind/metrics-server.yaml
```

**Validar**:
```bash
# Aguardar pod ficar Ready
kubectl get pods -n kube-system | grep metrics-server

# Testar métricas (pode demorar ~30s)
kubectl top nodes
```

**Esperado**: Ver uso de CPU e memória dos nós

---

## Deployando ServeRest

### Comandos Sequenciais

```bash
# 1. Namespace
kubectl apply -f k8s/serverest/00-namespace.yaml

# 2. ConfigMap
kubectl apply -f k8s/serverest/01-configmap.yaml

# 3. Deployment
kubectl apply -f k8s/serverest/02-deployment.yaml

# 4. Service
kubectl apply -f k8s/serverest/03-service.yaml

# 5. HPA
kubectl apply -f k8s/serverest/04-hpa.yaml
```

---

## Validando o Deploy

### Verificações Completas

```bash
# 1. Pods estão rodando?
kubectl get pods -n serverest

# 2. Service foi criado?
kubectl get svc -n serverest

# 3. HPA está ativo?
kubectl get hpa -n serverest

# 4. API está respondendo?
curl http://localhost:30000/
```

**Resposta esperada**: `{ "message": "Bem vindo ao ServeRest API" }`

---

## Entendendo o Status do HPA

### Exemplo de Output

```
NAME            REFERENCE            TARGETS   MINPODS   MAXPODS   REPLICAS
serverest-hpa   Deployment/serverest 5%/50%    2         10        2
```

**Interpretação**:
- **TARGETS**: `5%/50%` = CPU atual 5%, target 50%
- **MINPODS**: 2 = Mínimo de pods
- **MAXPODS**: 10 = Máximo de pods
- **REPLICAS**: 2 = Pods rodando agora

**Status**: CPU baixa (5%), então HPA mantém mínimo (2 pods)

---

## Testando o Auto-scaling

### Simulação Rápida

```bash
# Terminal 1: Monitorar HPA
kubectl get hpa -n serverest -w

# Terminal 2: Gerar carga (exemplo simples)
while true; do curl http://localhost:30000/usuarios; done
```

**Observe**:
- CPU começa a subir
- Quando passar de 50%, HPA cria mais pods
- REPLICAS aumenta: 2 → 3 → 4...

---

## Problemas Comuns

### Troubleshooting Rápido

**Pod não inicia**:
```bash
kubectl describe pod <nome> -n serverest
# Olhar seção "Events"
```

**HPA não escala**:
```bash
kubectl describe hpa serverest-hpa -n serverest
# Verificar se Metrics Server está rodando
kubectl top nodes
```

**API não responde**:
```bash
# Verificar logs do pod
kubectl logs <nome-pod> -n serverest
```

---

## Limpeza (Quando Necessário)

### Deletar Recursos

```bash
# Deletar tudo do namespace
kubectl delete namespace serverest

# Deletar cluster inteiro
kind delete cluster --name serverest-cluster
```

**Quando usar**:
- Recriar do zero
- Economizar recursos
- Finalizar laboratório

---

## Próximos Passos

### O que Vem Agora

✅ Cluster criado  
✅ ServeRest deployado  
✅ HPA configurado  

**Próximo**: 
- ☕ Break 10 minutos
- 📊 Escrever testes k6
- 🎯 Executar testes de carga
- 📈 Observar auto-scaling em ação!

---

## Resumo da Parte 2

### O que Aprendemos

✅ Kubernetes básico (Pod, Deployment, Service, HPA)  
✅ kind para clusters locais  
✅ Metrics Server para métricas  
✅ Criar cluster multi-node  
✅ Deploy de aplicação completa  
✅ Validar funcionamento  
✅ Comandos kubectl essenciais  

---

## Recursos para Aprofundar

### Links Úteis

**Kubernetes**:
- https://kubernetes.io/docs/tutorials/
- https://kubernetes.io/docs/concepts/

**kind**:
- https://kind.sigs.k8s.io/docs/user/quick-start/

**kubectl**:
- https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

## Exercício Rápido

### Desafio (5 minutos)

1. Liste todos os pods do namespace `serverest`
2. Veja os logs de um dos pods
3. Verifique o status do HPA
4. Faça um curl na API

**Compartilhe**: Quais comandos você usou?

---

## Dúvidas?

### Conceitos para Revisar

- Pod vs Deployment vs Service?
- Requests vs Limits?
- Como HPA decide escalar?
- Por que kind e não minikube?

**Qualquer dúvida é válida!**

---

# Notas para o Professor

## Timing Sugerido (40 minutos)

- Slides 1-15: Conceitos Kubernetes (10 min)
- Slides 16-30: kind e componentes (10 min)
- Slides 31-45: Demo ao vivo (15 min)
- Slides 46-50: Validação e troubleshooting (5 min)

## Dicas para a Demo

1. **Prepare com antecedência**: Rode o cluster antes da aula para testar
2. **Terminal visível**: Use fonte grande (20pt+)
3. **Explique cada comando**: Não apenas execute
4. **Mostre erros**: Se algo falhar, use como oportunidade de ensino
5. **Valide cada passo**: Não avance se algo não funcionou

## Material de Apoio

- Terminal com histórico de comandos
- Segundo monitor/projetor para slides
- Comandos salvos em arquivo texto (copiar/colar se necessário)

## Checkpoint para Alunos

Antes de prosseguir, garantir que TODOS:
- ✅ Têm cluster rodando
- ✅ Vêem 2 pods do ServeRest
- ✅ API responde em localhost:30000
- ✅ HPA está ativo

**Não avance se alguém ficou para trás!**

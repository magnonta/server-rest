# Manifestos Kubernetes para ServeRest

Este diretório contém todos os manifestos Kubernetes necessários para executar o ServeRest em um cluster local usando kind.

## 📁 Estrutura

```
k8s/
├── kind/                      # Configurações do cluster kind
│   ├── kind-config.yaml      # Config do cluster (1 control-plane + 2 workers)
│   └── metrics-server.yaml   # Metrics server para HPA
├── serverest/                 # Manifestos da aplicação
│   ├── 00-namespace.yaml     # Namespace 'serverest'
│   ├── 01-configmap.yaml     # Configurações da app
│   ├── 02-deployment.yaml    # Deployment com 2 réplicas
│   ├── 03-service.yaml       # Service NodePort (porta 30000)
│   └── 04-hpa.yaml           # HPA (auto-scaling 2-10 pods)
└── examples/                  # Exemplos adicionais
```

## 🚀 Quick Start

### 1. Criar cluster kind

```bash
# Criar cluster com configuração customizada
kind create cluster --config k8s/kind/kind-config.yaml

# Verificar se cluster foi criado
kubectl cluster-info --context kind-serverest-cluster
```

### 2. Instalar metrics-server

```bash
# Aplicar metrics-server (necessário para HPA)
kubectl apply -f k8s/kind/metrics-server.yaml

# Aguardar metrics-server ficar pronto
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=60s
```

### 3. Deploy do ServeRest

```bash
# Aplicar todos os manifestos
kubectl apply -f k8s/serverest/

# Ou aplicar individualmente em ordem
kubectl apply -f k8s/serverest/00-namespace.yaml
kubectl apply -f k8s/serverest/01-configmap.yaml
kubectl apply -f k8s/serverest/02-deployment.yaml
kubectl apply -f k8s/serverest/03-service.yaml
kubectl apply -f k8s/serverest/04-hpa.yaml
```

### 4. Verificar deployment

```bash
# Ver pods rodando
kubectl get pods -n serverest

# Ver service
kubectl get svc -n serverest

# Ver HPA
kubectl get hpa -n serverest

# Logs da aplicação
kubectl logs -f deployment/serverest -n serverest
```

### 5. Acessar a aplicação

A aplicação estará disponível em:
- **URL**: http://localhost:3000
- **Documentação**: http://localhost:3000/

## 📊 Observar Autoscaling

### Monitorar HPA em tempo real

```bash
# Watch do HPA
kubectl get hpa -n serverest --watch

# Métricas dos pods
kubectl top pods -n serverest

# Descrever HPA para ver eventos
kubectl describe hpa serverest-hpa -n serverest
```

### Forçar scaling manual (para testes)

```bash
# Aumentar réplicas manualmente
kubectl scale deployment serverest -n serverest --replicas=5

# Resetar para deixar HPA controlar
kubectl scale deployment serverest -n serverest --replicas=2
```

## 🧪 Testar com k6

Após executar testes de carga com k6, observe o HPA escalar automaticamente:

```bash
# Terminal 1: Monitorar HPA
watch kubectl get hpa -n serverest

# Terminal 2: Monitorar pods
watch kubectl get pods -n serverest

# Terminal 3: Executar teste de carga
k6 run k6/scripts/02-load-test.js
```

## 🔧 Comandos Úteis

### Namespace

```bash
# Ver recursos no namespace
kubectl get all -n serverest

# Descrever namespace
kubectl describe namespace serverest
```

### Logs

```bash
# Logs de um pod específico
kubectl logs <pod-name> -n serverest

# Logs de todos os pods do deployment
kubectl logs -l app=serverest -n serverest --tail=50

# Seguir logs em tempo real
kubectl logs -f deployment/serverest -n serverest
```

### Debug

```bash
# Entrar em um pod
kubectl exec -it <pod-name> -n serverest -- /bin/sh

# Port-forward para acessar um pod específico
kubectl port-forward -n serverest pod/<pod-name> 3000:3000

# Ver eventos do namespace
kubectl get events -n serverest --sort-by='.lastTimestamp'
```

### Limpeza

```bash
# Deletar todos os recursos do namespace
kubectl delete namespace serverest

# Deletar cluster kind
kind delete cluster --name serverest-cluster
```

## 📝 Configurações Importantes

### Resource Requests/Limits

No `02-deployment.yaml`:
```yaml
resources:
  requests:
    cpu: 100m      # CPU necessária para criar pod
    memory: 128Mi  # Memória necessária para criar pod
  limits:
    cpu: 500m      # Máximo de CPU
    memory: 512Mi  # Máximo de memória
```

**Importante**: O HPA usa `requests` como baseline para calcular utilização!

### HPA Configuration

No `04-hpa.yaml`:
```yaml
minReplicas: 2           # Mínimo de pods
maxReplicas: 10          # Máximo de pods
averageUtilization: 50   # Escala quando CPU > 50%
```

**Fórmula do HPA**:
```
desiredReplicas = ceil[currentReplicas * (currentMetricValue / targetMetricValue)]
```

### NodePort Configuration

No `03-service.yaml`:
```yaml
type: NodePort
nodePort: 30000  # Porta fixa para facilitar acesso
```

A porta 30000 foi mapeada no `kind-config.yaml` para aparecer como 3000 no host.

## ⚠️ Troubleshooting

### HPA mostra `<unknown>` nas métricas

```bash
# Verificar se metrics-server está rodando
kubectl get pods -n kube-system | grep metrics-server

# Ver logs do metrics-server
kubectl logs -n kube-system deployment/metrics-server

# Aguardar alguns segundos para métricas aparecerem
kubectl top nodes
kubectl top pods -n serverest
```

### Pods não sobem (ImagePullBackOff)

```bash
# Ver detalhes do pod
kubectl describe pod <pod-name> -n serverest

# Verificar se imagem existe
docker pull paulogoncalvesbh/serverest:latest
```

### Service não acessível

```bash
# Verificar se service foi criado
kubectl get svc -n serverest

# Verificar mapeamento de portas do kind
docker ps | grep serverest-cluster
```

### Pods crashando

```bash
# Ver logs do pod
kubectl logs <pod-name> -n serverest

# Ver eventos
kubectl describe pod <pod-name> -n serverest
```

## 🎓 Para Alunos

### Exercícios Práticos

1. **Modificar resources**: Altere CPU request para 50m e observe comportamento do HPA
2. **Ajustar HPA**: Modifique `averageUtilization` para 30% e teste scaling
3. **Aumentar réplicas**: Ajuste `minReplicas` e `maxReplicas`
4. **Adicionar health checks**: Experimente com diferentes valores de probes
5. **Testar rolling updates**: Altere a imagem e observe o deployment

### Desafios

- Configurar affinity/anti-affinity
- Adicionar PodDisruptionBudget
- Implementar Ingress
- Configurar NetworkPolicy
- Adicionar limites de namespace (ResourceQuota)

## 📚 Referências

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kind Documentation](https://kind.sigs.k8s.io/)
- [HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)
- [ServeRest](https://github.com/ServeRest/ServeRest)

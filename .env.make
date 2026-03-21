# ============================================================================
# CONFIGURAÇÃO LOCAL DO MAKEFILE
# ============================================================================
# Gerado a partir de .env.make.example
# Ajuste conforme necessário
# ============================================================================

# Cluster Kubernetes
KIND_CLUSTER_NAME=serverest-cluster
K8S_NAMESPACE=serverest

# URL da aplicação (usado nos testes)
BASE_URL=http://localhost:30000

# Timeouts
POD_READY_TIMEOUT=120s
METRICS_WAIT_TIME=30

# Modo verbose (0 = desativado, 1 = ativado)
VERBOSE=0

# k6 Web Dashboard - dashboards HTML interativos
K6_DASHBOARD=true
K6_DASHBOARD_OPEN=true

#!/bin/bash
# ============================================================================
# CLUSTER STATUS
# ============================================================================
# Mostra status detalhado do cluster kind
# Uso: cluster-status.sh <cluster-name> <namespace>
# ============================================================================

CLUSTER_NAME=${1:?Cluster name é obrigatório}
NAMESPACE=${2:-serverest}

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD}  STATUS DO CLUSTER${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo ""

# Verificar se cluster existe
if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${RED}❌ Cluster não existe: ${CLUSTER_NAME}${RESET}"
    exit 1
fi

echo -e "${GREEN}✅ Cluster existe: ${CLUSTER_NAME}${RESET}"
echo ""

# Contexto atual
echo -e "${BOLD}Contexto kubectl:${RESET}"
kubectl config current-context
echo ""

# Nodes
echo -e "${BOLD}Nodes:${RESET}"
kubectl get nodes -o wide
echo ""

# Namespaces
echo -e "${BOLD}Namespaces:${RESET}"
kubectl get namespaces
echo ""

# Recursos no namespace especificado
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo -e "${BOLD}Recursos no namespace '${NAMESPACE}':${RESET}"
    kubectl get all -n "$NAMESPACE" 2>/dev/null || echo "  (nenhum recurso)"
else
    echo -e "${YELLOW}Namespace '${NAMESPACE}' não existe${RESET}"
fi

echo ""

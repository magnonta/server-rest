#!/bin/bash
# ============================================================================
# WAIT FOR PODS
# ============================================================================
# Aguarda pods ficarem prontos com retry e timeout
# Uso: wait-for-pods.sh <namespace> <label-selector> <timeout>
# Exemplo: wait-for-pods.sh serverest "app=serverest" 120s
# ============================================================================

set -e

NAMESPACE=${1:?Namespace é obrigatório}
LABEL_SELECTOR=${2:?Label selector é obrigatório}
TIMEOUT=${3:-120s}

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${YELLOW}Aguardando pods ficarem prontos...${RESET}"
echo "  Namespace: $NAMESPACE"
echo "  Label: $LABEL_SELECTOR"
echo "  Timeout: $TIMEOUT"
echo ""

# Aguardar pods ficarem prontos
if kubectl wait --for=condition=ready pod \
    -l "$LABEL_SELECTOR" \
    -n "$NAMESPACE" \
    --timeout="$TIMEOUT" 2>&1; then
    echo -e "${GREEN}✅ Pods prontos!${RESET}"
    exit 0
else
    echo -e "${RED}❌ Timeout aguardando pods${RESET}"
    echo ""
    echo "Pods atuais:"
    kubectl get pods -n "$NAMESPACE" -l "$LABEL_SELECTOR"
    echo ""
    echo "Eventos recentes:"
    kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -10
    exit 1
fi

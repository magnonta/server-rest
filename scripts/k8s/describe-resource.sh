#!/bin/bash
# ============================================================================
# DESCRIBE RESOURCE (INTERATIVO)
# ============================================================================
# Lista recursos e permite seleção interativa para describe
# Uso: describe-resource.sh <resource-type> <namespace>
# Exemplo: describe-resource.sh pod serverest
# ============================================================================

RESOURCE_TYPE=${1:?Resource type é obrigatório (pod, deployment, service, etc)}
NAMESPACE=${2:?Namespace é obrigatório}

# Cores
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD}  RECURSOS DISPONÍVEIS${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo ""

# Listar recursos
kubectl get "$RESOURCE_TYPE" -n "$NAMESPACE"

echo ""
echo -e "${YELLOW}Digite o nome do $RESOURCE_TYPE para descrever:${RESET}"
read -p "Nome: " RESOURCE_NAME

if [ -z "$RESOURCE_NAME" ]; then
    echo "Nenhum nome fornecido. Saindo."
    exit 0
fi

echo ""
echo -e "${BOLD}Descrevendo $RESOURCE_TYPE/$RESOURCE_NAME...${RESET}"
echo ""

kubectl describe "$RESOURCE_TYPE" "$RESOURCE_NAME" -n "$NAMESPACE"

#!/bin/bash
# ============================================================================
# EXEC POD (INTERATIVO)
# ============================================================================
# Lista pods e permite seleção interativa para shell
# Uso: exec-pod.sh <namespace>
# ============================================================================

NAMESPACE=${1:?Namespace é obrigatório}

# Cores
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD}  PODS DISPONÍVEIS${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo ""

# Listar pods
kubectl get pods -n "$NAMESPACE"

echo ""
echo -e "${YELLOW}Digite o nome do pod para abrir shell:${RESET}"
read -p "Nome: " POD_NAME

if [ -z "$POD_NAME" ]; then
    echo "Nenhum nome fornecido. Saindo."
    exit 0
fi

echo ""
echo -e "${BOLD}Abrindo shell em $POD_NAME...${RESET}"
echo -e "${YELLOW}(Use 'exit' para sair)${RESET}"
echo ""

kubectl exec -it "$POD_NAME" -n "$NAMESPACE" -- /bin/sh

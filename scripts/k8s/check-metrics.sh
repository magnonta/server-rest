#!/bin/bash
# ============================================================================
# CHECK METRICS
# ============================================================================
# Verifica se Metrics Server está funcionando
# Tenta kubectl top nodes até conseguir ou dar timeout
# ============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

MAX_RETRIES=10
RETRY_DELAY=3

echo -e "${YELLOW}Verificando disponibilidade das métricas...${RESET}"

for i in $(seq 1 $MAX_RETRIES); do
    echo -n "  Tentativa $i/$MAX_RETRIES... "
    
    if kubectl top nodes &> /dev/null; then
        echo -e "${GREEN}✅ Métricas disponíveis!${RESET}"
        echo ""
        kubectl top nodes
        exit 0
    else
        echo -e "${YELLOW}aguardando...${RESET}"
        sleep $RETRY_DELAY
    fi
done

echo -e "${RED}❌ Métricas não ficaram disponíveis${RESET}"
echo ""
echo "Verifique o Metrics Server:"
echo "  kubectl get pods -n kube-system -l k8s-app=metrics-server"
exit 1

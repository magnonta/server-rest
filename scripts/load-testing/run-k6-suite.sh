#!/bin/bash
# ============================================================================
# RUN K6 TEST SUITE
# ============================================================================
# Executa suite completa de testes k6 com relatório consolidado
# Uso: run-k6-suite.sh <base-url> <scripts-dir> <verbose>
# ============================================================================

set -e

BASE_URL=${1:?BASE_URL é obrigatório}
SCRIPTS_DIR=${2:?Scripts directory é obrigatório}
VERBOSE=${3:-0}

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# Configuração de output
if [ "$VERBOSE" = "1" ]; then
    QUIET_FLAG=""
else
    QUIET_FLAG="--quiet"
fi

# Array de testes (ordem de execução)
TESTS=(
    "00-health-check.js:Health Check"
    "01-smoke-test.js:Smoke Test"
    "02-load-test.js:Load Test"
    "03-stress-test.js:Stress Test"
    "04-spike-test.js:Spike Test"
)

# Contadores
TOTAL_TESTS=${#TESTS[@]}
PASSED=0
FAILED=0

echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD}  K6 TEST SUITE${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo ""
echo "BASE_URL: $BASE_URL"
echo "Total de testes: $TOTAL_TESTS"
echo ""

# Executar cada teste
for test_info in "${TESTS[@]}"; do
    IFS=':' read -r test_file test_name <<< "$test_info"
    test_path="$SCRIPTS_DIR/$test_file"
    
    echo -e "${BOLD}Executando: $test_name${RESET}"
    echo "  Arquivo: $test_file"
    echo ""
    
    if BASE_URL="$BASE_URL" k6 run "$test_path" $QUIET_FLAG; then
        echo -e "${GREEN}✅ $test_name - PASSOU${RESET}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ $test_name - FALHOU${RESET}"
        FAILED=$((FAILED + 1))
    fi
    
    echo ""
    echo "---"
    echo ""
done

# Relatório final
echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD}  RELATÓRIO FINAL${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo ""
echo "Total de testes: $TOTAL_TESTS"
echo -e "${GREEN}Passaram: $PASSED${RESET}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Falharam: $FAILED${RESET}"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ TODOS OS TESTES PASSARAM!${RESET}"
    exit 0
else
    echo -e "${RED}❌ ALGUNS TESTES FALHARAM${RESET}"
    exit 1
fi

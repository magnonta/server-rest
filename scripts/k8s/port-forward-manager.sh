#!/bin/bash
# ============================================================================
# PORT FORWARD MANAGER
# ============================================================================
# Gerencia port-forward em background com PID file
# Uso:
#   port-forward-manager.sh start <namespace> <service> <local-port> <remote-port> <pid-file>
#   port-forward-manager.sh stop <pid-file>
#   port-forward-manager.sh status <pid-file>
# ============================================================================

set -e

COMMAND=${1:?Comando é obrigatório (start|stop|status)}

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

case "$COMMAND" in
    start)
        NAMESPACE=${2:?Namespace é obrigatório}
        SERVICE=${3:?Service é obrigatório}
        LOCAL_PORT=${4:?Porta local é obrigatória}
        REMOTE_PORT=${5:?Porta remota é obrigatória}
        PID_FILE=${6:?PID file é obrigatório}
        
        # Verificar se já está rodando
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo -e "${YELLOW}⚠️  Port-forward já está rodando (PID: $(cat $PID_FILE))${RESET}"
            exit 0
        fi
        
        # Iniciar port-forward em background
        kubectl port-forward -n "$NAMESPACE" "svc/$SERVICE" "${LOCAL_PORT}:${REMOTE_PORT}" > /dev/null 2>&1 &
        PID=$!
        
        # Salvar PID
        mkdir -p "$(dirname "$PID_FILE")"
        echo $PID > "$PID_FILE"
        
        # Aguardar um pouco para garantir que iniciou
        sleep 2
        
        # Verificar se está rodando
        if kill -0 $PID 2>/dev/null; then
            echo -e "${GREEN}✅ Port-forward iniciado (PID: $PID)${RESET}"
            echo "  Local: http://localhost:${LOCAL_PORT}"
            echo "  Remoto: ${NAMESPACE}/${SERVICE}:${REMOTE_PORT}"
        else
            echo -e "${RED}❌ Erro ao iniciar port-forward${RESET}"
            rm -f "$PID_FILE"
            exit 1
        fi
        ;;
        
    stop)
        PID_FILE=${2:?PID file é obrigatório}
        
        if [ ! -f "$PID_FILE" ]; then
            echo -e "${YELLOW}⚠️  Port-forward não está rodando${RESET}"
            exit 0
        fi
        
        PID=$(cat "$PID_FILE")
        
        if kill -0 $PID 2>/dev/null; then
            kill $PID 2>/dev/null || true
            rm -f "$PID_FILE"
            echo -e "${GREEN}✅ Port-forward parado${RESET}"
        else
            echo -e "${YELLOW}⚠️  Processo já não existe${RESET}"
            rm -f "$PID_FILE"
        fi
        ;;
        
    status)
        PID_FILE=${2:?PID file é obrigatório}
        
        if [ ! -f "$PID_FILE" ]; then
            echo -e "${RED}❌ Não ativo${RESET}"
            exit 1
        fi
        
        PID=$(cat "$PID_FILE")
        
        if kill -0 $PID 2>/dev/null; then
            echo -e "${GREEN}✅ Ativo (PID: $PID)${RESET}"
            exit 0
        else
            echo -e "${RED}❌ Processo não encontrado${RESET}"
            rm -f "$PID_FILE"
            exit 1
        fi
        ;;
        
    *)
        echo -e "${RED}Comando inválido: $COMMAND${RESET}"
        echo "Uso: $0 {start|stop|status} <args>"
        exit 1
        ;;
esac

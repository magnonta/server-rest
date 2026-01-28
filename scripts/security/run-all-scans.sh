#!/bin/bash
# Script para executar scan de segurança com Trivy

set -e

echo "🔒 Iniciando scan de segurança com Trivy..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Diretórios
SECURITY_DIR="security"
REPORTS_DIR="$SECURITY_DIR/reports"
TRIVY_CONFIG="$SECURITY_DIR/trivy/trivy.yaml"

# Criar diretório de reports se não existir
mkdir -p "$REPORTS_DIR"

# Data atual para nomear reports
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo ""
echo "📦 1. Scanning de dependências (package.json)..."
trivy fs \
  --config "$TRIVY_CONFIG" \
  --format json \
  --output "$REPORTS_DIR/dependencies-scan-$TIMESTAMP.json" \
  --severity CRITICAL,HIGH,MEDIUM \
  . || echo -e "${YELLOW}⚠️  Vulnerabilidades encontradas em dependências${NC}"

echo ""
echo "🐳 2. Scanning de imagem Docker..."
trivy image \
  --config "$TRIVY_CONFIG" \
  --format json \
  --output "$REPORTS_DIR/image-scan-$TIMESTAMP.json" \
  --severity CRITICAL,HIGH \
  paulogoncalvesbh/serverest:latest || echo -e "${YELLOW}⚠️  Vulnerabilidades encontradas na imagem${NC}"

echo ""
echo "📄 3. Scanning de arquivos de configuração..."
trivy config \
  --format json \
  --output "$REPORTS_DIR/config-scan-$TIMESTAMP.json" \
  . || echo -e "${YELLOW}⚠️  Problemas encontrados em configurações${NC}"

echo ""
echo "🔑 4. Scanning de secrets..."
trivy fs \
  --scanners secret \
  --format json \
  --output "$REPORTS_DIR/secrets-scan-$TIMESTAMP.json" \
  . || echo -e "${YELLOW}⚠️  Possíveis secrets encontrados${NC}"

echo ""
echo -e "${GREEN}✅ Scan completo!${NC}"
echo ""
echo "📊 Relatórios gerados em: $REPORTS_DIR/"
echo "  - dependencies-scan-$TIMESTAMP.json"
echo "  - image-scan-$TIMESTAMP.json"
echo "  - config-scan-$TIMESTAMP.json"
echo "  - secrets-scan-$TIMESTAMP.json"
echo ""
echo "💡 Para visualizar relatórios em formato legível:"
echo "   cat $REPORTS_DIR/dependencies-scan-$TIMESTAMP.json | jq"

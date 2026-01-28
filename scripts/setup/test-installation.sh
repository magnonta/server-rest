#!/bin/bash
# ============================================================================
# INSTALLATION SMOKE TEST
# ============================================================================
# Tests that all installed tools work correctly with basic functionality
# Creates minimal resources and cleans up after itself
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Test cluster name
TEST_CLUSTER="test-installation-$$"
TEST_FAILED=0

echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD}  INSTALLATION SMOKE TEST${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo ""
echo -e "${CYAN}This test will:${RESET}"
echo "  1. Verify all tools are installed"
echo "  2. Test Docker with a simple container"
echo "  3. Create a minimal kind cluster"
echo "  4. Deploy a test pod"
echo "  5. Run a basic k6 test"
echo "  6. Clean up everything"
echo ""
echo -e "${YELLOW}This will take about 2-3 minutes...${RESET}"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo -e "${BOLD}Cleaning up test resources...${RESET}"
    
    # Delete kind cluster if it exists
    if kind get clusters 2>/dev/null | grep -q "^${TEST_CLUSTER}$"; then
        echo -n "  Deleting test cluster... "
        kind delete cluster --name "$TEST_CLUSTER" &>/dev/null && echo -e "${GREEN}✓${RESET}" || echo -e "${YELLOW}skipped${RESET}"
    fi
    
    echo -e "${GREEN}✓ Cleanup complete${RESET}"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# ============================================================================
# TEST 1: Verify Tools
# ============================================================================
echo -e "${BOLD}[1/5] Verifying tools...${RESET}"

check_tool() {
    local cmd=$1
    local name=$2
    echo -n "  $name... "
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${RESET}"
        return 0
    else
        echo -e "${RED}✗ NOT FOUND${RESET}"
        TEST_FAILED=1
        return 1
    fi
}

check_tool "docker" "Docker"
check_tool "kubectl" "kubectl"
check_tool "kind" "kind"
check_tool "k6" "k6"
check_tool "node" "Node.js"
check_tool "npm" "npm"

if [ $TEST_FAILED -eq 1 ]; then
    echo -e "${RED}✗ Some tools are missing. Run 'make install-tools' first.${RESET}"
    exit 1
fi

echo ""

# ============================================================================
# TEST 2: Docker Functionality
# ============================================================================
echo -e "${BOLD}[2/5] Testing Docker...${RESET}"

echo -n "  Docker daemon running... "
if docker ps &> /dev/null; then
    echo -e "${GREEN}✓${RESET}"
else
    echo -e "${RED}✗ Docker daemon not running${RESET}"
    echo -e "${YELLOW}  Please start Docker Desktop and try again${RESET}"
    exit 1
fi

echo -n "  Pulling hello-world image... "
if docker pull hello-world:latest &> /dev/null; then
    echo -e "${GREEN}✓${RESET}"
else
    echo -e "${RED}✗ Failed to pull image${RESET}"
    TEST_FAILED=1
fi

echo -n "  Running test container... "
if docker run --rm hello-world &> /dev/null; then
    echo -e "${GREEN}✓${RESET}"
else
    echo -e "${RED}✗ Failed to run container${RESET}"
    TEST_FAILED=1
fi

if [ $TEST_FAILED -eq 1 ]; then
    echo -e "${RED}✗ Docker test failed${RESET}"
    exit 1
fi

echo ""

# ============================================================================
# TEST 3: Create Kind Cluster
# ============================================================================
echo -e "${BOLD}[3/5] Testing kind (Kubernetes)...${RESET}"

echo -n "  Creating test cluster... "
if kind create cluster --name "$TEST_CLUSTER" --quiet --wait 60s &> /dev/null; then
    echo -e "${GREEN}✓${RESET}"
else
    echo -e "${RED}✗ Failed to create cluster${RESET}"
    exit 1
fi

echo -n "  Testing kubectl connectivity... "
if kubectl get nodes --context "kind-${TEST_CLUSTER}" &> /dev/null; then
    echo -e "${GREEN}✓${RESET}"
else
    echo -e "${RED}✗ Cannot connect to cluster${RESET}"
    exit 1
fi

echo ""

# ============================================================================
# TEST 4: Deploy Test Pod
# ============================================================================
echo -e "${BOLD}[4/5] Testing Kubernetes deployment...${RESET}"

echo -n "  Creating test pod... "
if kubectl run test-nginx --image=nginx:alpine --context "kind-${TEST_CLUSTER}" &> /dev/null; then
    echo -e "${GREEN}✓${RESET}"
else
    echo -e "${RED}✗ Failed to create pod${RESET}"
    exit 1
fi

echo -n "  Waiting for pod to be ready... "
if kubectl wait --for=condition=ready pod/test-nginx --timeout=60s --context "kind-${TEST_CLUSTER}" &> /dev/null; then
    echo -e "${GREEN}✓${RESET}"
else
    echo -e "${RED}✗ Pod not ready in time${RESET}"
    exit 1
fi

echo -n "  Verifying pod is running... "
if kubectl get pod test-nginx --context "kind-${TEST_CLUSTER}" -o jsonpath='{.status.phase}' 2>/dev/null | grep -q "Running"; then
    echo -e "${GREEN}✓${RESET}"
else
    echo -e "${RED}✗ Pod not running${RESET}"
    exit 1
fi

echo -n "  Deleting test pod... "
if kubectl delete pod test-nginx --context "kind-${TEST_CLUSTER}" --wait=false &> /dev/null; then
    echo -e "${GREEN}✓${RESET}"
else
    echo -e "${YELLOW}⚠ Could not delete pod${RESET}"
fi

echo ""

# ============================================================================
# TEST 5: Test k6
# ============================================================================
echo -e "${BOLD}[5/5] Testing k6 (load testing)...${RESET}"

# Create minimal k6 test
cat > /tmp/test-k6-$$.js << 'EOF'
import http from 'k6/http';
import { check } from 'k6';

export let options = {
    vus: 1,
    iterations: 1,
};

export default function() {
    let res = http.get('https://test.k6.io/');
    check(res, {
        'status is 200': (r) => r.status === 200,
    });
}
EOF

echo -n "  Running k6 test... "
if k6 run /tmp/test-k6-$$.js &> /dev/null; then
    echo -e "${GREEN}✓${RESET}"
else
    echo -e "${RED}✗ k6 test failed${RESET}"
    TEST_FAILED=1
fi

# Cleanup k6 test file
rm -f /tmp/test-k6-$$.js

echo ""

# ============================================================================
# RESULTS
# ============================================================================
echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD}  TEST RESULTS${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo ""

if [ $TEST_FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ ALL TESTS PASSED!${RESET}"
    echo ""
    echo -e "${CYAN}Your installation is working correctly.${RESET}"
    echo ""
    echo -e "${BOLD}Next steps:${RESET}"
    echo "  1. make bootstrap     # Create full environment"
    echo "  2. make lab-aula-01   # Run load testing lab"
    echo "  3. make lab-aula-02   # Run security testing lab"
    echo ""
    exit 0
else
    echo -e "${RED}${BOLD}❌ SOME TESTS FAILED${RESET}"
    echo ""
    echo -e "${YELLOW}Please check the errors above and:${RESET}"
    echo "  1. Verify Docker is running"
    echo "  2. Check network connectivity"
    echo "  3. Try running 'make install-tools' again"
    echo ""
    exit 1
fi

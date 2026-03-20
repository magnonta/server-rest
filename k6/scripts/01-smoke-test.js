// Smoke Test
// Teste mínimo para verificar funcionalidade básica
// Executa com 1-2 usuários virtuais por curto período
// Objetivo: Validar que o sistema funciona sem carga
// Uso: k6 run k6/scripts/01-smoke-test.js

import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { BASE_URL, DEFAULT_THRESHOLDS, getStages } from '../modules/config.js';
import { 
  listarUsuarios, 
  listarProdutos 
} from '../modules/serverest-api.js';

export const options = {
  stages: getStages('smoke'),
  thresholds: {
    ...DEFAULT_THRESHOLDS,
    // Smoke test deve ter resposta muito rápida
    'http_req_duration': ['p(95)<300'],
  },
};

export default function () {
  group('Health Check', () => {
    const response = http.get(BASE_URL);
    check(response, {
      'API está online': (r) => r.status === 200,
    });
  });

  group('Listar Recursos', () => {
    // Listar usuários
    listarUsuarios(BASE_URL);
    sleep(1);
    
    // Listar produtos
    listarProdutos(BASE_URL);
    sleep(1);
  });
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'k6/results/smoke-test-summary.json': JSON.stringify(data),
  };
}

// Helper para summary (opcional)
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

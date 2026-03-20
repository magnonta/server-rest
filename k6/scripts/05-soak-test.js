// Soak Test (Endurance Test)
// Teste de resistência - mantém carga constante por longo período
// Executa por 30+ minutos com carga moderada
// Objetivo: Identificar problemas de memory leak, degradação, etc.
// Uso: k6 run k6/scripts/05-soak-test.js

import { group, check, sleep } from 'k6';
import { Trend, Counter } from 'k6/metrics';
import { BASE_URL, getStages } from '../modules/config.js';
import {
  criarUsuario,
  fazerLogin,
  listarProdutos,
  criarProduto,
  thinkTime,
} from '../modules/serverest-api.js';

// Métricas customizadas para monitorar degradação ao longo do tempo
const responseTimeTrend = new Trend('custom_response_time');
const businessErrors = new Counter('business_errors');

export const options = {
  stages: getStages('soak'),
  thresholds: {
    // Soak test deve manter qualidade por longo período
    'http_req_duration': ['p(95)<1000'],
    'http_req_duration{expected_response:true}': ['p(99)<2000'],
    'http_req_failed': ['rate<0.02'], // Máximo 2% de erro
    'checks': ['rate>0.95'],
    // Métrica customizada não deve degradar
    'custom_response_time': ['p(95)<1000'],
  },
};

export default function () {
  const timestamp = Date.now();
  const vuId = __VU;
  const iterationId = __ITER;
  const uniqueEmail = `soak-${vuId}-${iterationId}-${timestamp}@test.com`;

  const startTime = Date.now();

  group('Fluxo Completo de Usuário', () => {
    try {
      // 1. Registro
      const userData = {
        nome: `Soak Test User ${vuId}`,
        email: uniqueEmail,
        password: 'senha123',
        administrador: 'true',
      };
      
      criarUsuario(BASE_URL, userData);
      thinkTime(1, 2);
      
      // 2. Login
      const token = fazerLogin(BASE_URL, uniqueEmail, 'senha123');
      
      if (!token) {
        businessErrors.add(1);
      }
      
      thinkTime(1, 2);
      
      // 3. Navegar produtos
      listarProdutos(BASE_URL);
      thinkTime(2, 3);
      
      // 4. Criar produto
      const productData = {
        nome: `Produto Soak ${vuId}-${iterationId}`,
        preco: Math.floor(Math.random() * 500) + 50,
        descricao: 'Produto para teste de resistência',
        quantidade: Math.floor(Math.random() * 50) + 10,
      };
      
      const productResponse = criarProduto(BASE_URL, token, productData);
      
      check(productResponse, {
        'produto criado': (r) => r.status === 201,
      }) || businessErrors.add(1);
      
      thinkTime(1, 2);
      
    } catch (error) {
      businessErrors.add(1);
      console.error(`Erro na iteração ${iterationId}: ${error}`);
    }
  });

  // Registrar tempo de resposta total
  const endTime = Date.now();
  responseTimeTrend.add(endTime - startTime);
  
  // Think time normal
  thinkTime(2, 4);
}

export function handleSummary(data) {
  const testDurationMinutes = 40; // 5 min ramp-up + 30 min soak + 5 min ramp-down
  
  const summary = {
    timestamp: new Date().toISOString(),
    test_type: 'soak',
    test_duration_minutes: testDurationMinutes,
    target_vus: 20,
    total_requests: data.metrics.http_reqs.values.count,
    requests_per_second: data.metrics.http_reqs.values.rate,
    failed_requests: data.metrics.http_req_failed ? data.metrics.http_req_failed.values.passes : 0,
    business_errors: data.metrics.business_errors ? data.metrics.business_errors.values.count : 0,
    avg_response_time: data.metrics.http_req_duration.values.avg,
    p50_response_time: data.metrics.http_req_duration.values.med,
    p95_response_time: data.metrics.http_req_duration.values['p(95)'],
    p99_response_time: data.metrics.http_req_duration.values['p(99)'],
    max_response_time: data.metrics.http_req_duration.values.max,
    // Verificar se houve degradação ao longo do tempo
    custom_response_trend: data.metrics.custom_response_time ? {
      avg: data.metrics.custom_response_time.values.avg,
      max: data.metrics.custom_response_time.values.max,
      p95: data.metrics.custom_response_time.values['p(95)'],
    } : null,
  };

  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'k6/results/soak-test-summary.json': JSON.stringify(data),
    'k6/results/soak-test-analysis.json': JSON.stringify(summary, null, 2),
    'k6/results/soak-test-summary.html': htmlReport(data),
  };
}

import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';
import { htmlReport } from 'https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js';

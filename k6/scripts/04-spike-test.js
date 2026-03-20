// Spike Test
// Teste de pico - aumenta carga drasticamente de forma súbita
// Simula situações como: Black Friday, lançamentos, campanhas virais
// Objetivo: Validar comportamento em picos repentinos de acesso
// Uso: k6 run k6/scripts/04-spike-test.js

import { group, check, sleep } from 'k6';
import { Rate } from 'k6/metrics';
import { BASE_URL, getStages } from '../modules/config.js';
import {
  listarProdutos,
  listarUsuarios,
  buscarProduto,
} from '../modules/serverest-api.js';

// Métrica customizada para medir taxa de sucesso durante spike
const spikeSuccessRate = new Rate('spike_success_rate');

export const options = {
  stages: getStages('spike'),
  thresholds: {
    // Durante spikes, aceitamos degradação temporária
    'http_req_duration': ['p(95)<3000'], // 3s
    'http_req_failed': ['rate<0.10'], // Até 10% de falha
    'spike_success_rate': ['rate>0.80'], // 80% de sucesso nos spikes
  },
};

export default function () {
  // Durante spike, operações são mais simples e rápidas
  group('Leitura Rápida de Dados', () => {
    // Listar produtos (operação comum)
    const productsResponse = listarProdutos(BASE_URL);
    const success = check(productsResponse, {
      'status é 200': (r) => r.status === 200,
    });
    
    spikeSuccessRate.add(success);
    sleep(0.2);
    
    // Listar usuários
    const usersResponse = listarUsuarios(BASE_URL);
    const usersSuccess = check(usersResponse, {
      'status é 200': (r) => r.status === 200,
    });
    
    spikeSuccessRate.add(usersSuccess);
    sleep(0.2);
    
    // Se temos produtos, buscar detalhes de um
    const products = productsResponse.status === 200 ? productsResponse.json('produtos') : [];
    if (products && products.length > 0) {
      const randomProduct = products[Math.floor(Math.random() * products.length)];
      const productResponse = buscarProduto(BASE_URL, randomProduct._id);
      
      const productSuccess = check(productResponse, {
        'produto encontrado': (r) => r.status === 200,
      });
      
      spikeSuccessRate.add(productSuccess);
    }
  });
  
  // Mínimo de sleep durante spike
  sleep(0.3);
}

export function handleSummary(data) {
  const currentStage = data.root_group.groups['Leitura Rápida de Dados'];
  
  const summary = {
    timestamp: new Date().toISOString(),
    test_type: 'spike',
    spike_target_vus: 100,
    baseline_vus: 10,
    total_requests: data.metrics.http_reqs.values.count,
    failed_requests: data.metrics.http_req_failed ? data.metrics.http_req_failed.values.passes : 0,
    spike_success_rate: data.metrics.spike_success_rate ? data.metrics.spike_success_rate.values.rate : 0,
    avg_response_time: data.metrics.http_req_duration.values.avg,
    max_response_time: data.metrics.http_req_duration.values.max,
    p95_response_time: data.metrics.http_req_duration.values['p(95)'],
    p99_response_time: data.metrics.http_req_duration.values['p(99)'],
  };

  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'k6/results/spike-test-summary.json': JSON.stringify(data),
    'k6/results/spike-test-analysis.json': JSON.stringify(summary, null, 2),
    'k6/results/spike-test-summary.html': htmlReport(data),
  };
}

import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';
import { htmlReport } from 'https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js';

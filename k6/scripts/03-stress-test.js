// Stress Test
// Teste de estresse - aumenta carga gradualmente até encontrar limites
// Vai de 10 até 300 usuários virtuais
// Objetivo: Encontrar ponto de quebra do sistema
// Uso: k6 run k6/scripts/03-stress-test.js

import { group, check, sleep } from 'k6';
import { Counter } from 'k6/metrics';
import { BASE_URL, getStages } from '../modules/config.js';
import {
  criarUsuario,
  fazerLogin,
  listarProdutos,
  criarCarrinho,
  concluirCompra,
  thinkTime,
} from '../modules/serverest-api.js';

// Métricas customizadas
const errorCounter = new Counter('custom_errors');

export const options = {
  stages: getStages('stress'),
  thresholds: {
    // Stress test tem thresholds mais relaxados
    'http_req_duration': ['p(95)<2000'], // 2s
    'http_req_duration{expected_response:true}': ['p(99)<3000'], // 3s
    'http_req_failed': ['rate<0.05'], // Até 5% de erro é aceitável em stress
    'checks': ['rate>0.85'], // 85% de checks passando
  },
};

export default function () {
  const timestamp = Date.now();
  const vuId = __VU;
  const iterationId = __ITER;
  const uniqueEmail = `stress-${vuId}-${iterationId}-${timestamp}@test.com`;

  // Cenário de stress: fluxo de compra completo
  group('Fluxo de Compra Completo', () => {
    try {
      // 1. Criar usuário
      const userData = {
        nome: `Stress User ${vuId}`,
        email: uniqueEmail,
        password: 'senha123',
        administrador: 'false',
      };
      
      const userResponse = criarUsuario(BASE_URL, userData);
      
      if (userResponse.status !== 201) {
        errorCounter.add(1);
      }
      
      sleep(0.5);
      
      // 2. Login
      const token = fazerLogin(BASE_URL, uniqueEmail, 'senha123');
      
      if (!token) {
        errorCounter.add(1);
      }
      
      sleep(0.5);
      
      if (token) {
        // 3. Listar produtos para poder adicionar ao carrinho
        const produtosRes = listarProdutos(BASE_URL);
        sleep(0.3);
        
        // Se listarProdutos teve sucesso, simularemos a adição do item ao carrinho
        if (produtosRes.status === 200) {
          const produtos = produtosRes.json('produtos');
          
          if (produtos && produtos.length > 0) {
            const produtoSorteado = produtos[Math.floor(Math.random() * produtos.length)];
            
            // 4. Criar carrinho
            const cartRes = criarCarrinho(BASE_URL, token, [
              {
                idProduto: produtoSorteado._id,
                quantidade: 1
              }
            ]);
            
            if (cartRes.status !== 201) {
              errorCounter.add(1);
            }
            
            sleep(0.5);
            
            // 5. Concluir a compra (isso limpa o carrinho para possibilitar futuras ações do VU)
            if (cartRes.status === 201) {
              const buyRes = concluirCompra(BASE_URL, token);
              if (buyRes.status !== 200) {
                errorCounter.add(1);
              }
            }
          }
        }
      }
      
    } catch (error) {
      errorCounter.add(1);
      console.error(`Erro na iteração ${iterationId} do VU ${vuId}: ${error}`);
    }
  });
  
  // Think time mínimo durante stress
  thinkTime(0.5, 1);
}

export function handleSummary(data) {
  // Relatório detalhado do stress test
  const summary = {
    timestamp: new Date().toISOString(),
    test_type: 'stress',
    max_vus: 300,
    total_requests: data.metrics.http_reqs.values.count,
    failed_requests: data.metrics.http_req_failed.values.passes,
    avg_response_time: data.metrics.http_req_duration.values.avg,
    p95_response_time: data.metrics.http_req_duration.values['p(95)'],
    p99_response_time: data.metrics.http_req_duration.values['p(99)'],
    custom_errors: data.metrics.custom_errors ? data.metrics.custom_errors.values.count : 0,
  };

  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'k6/results/stress-test-summary.json': JSON.stringify(data),
    'k6/results/stress-test-analysis.json': JSON.stringify(summary, null, 2),
    'k6/results/stress-test-summary.html': htmlReport(data),
  };
}

import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';
import { htmlReport } from 'https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js';

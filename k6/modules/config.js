// Configurações globais e constantes para os testes k6
// Este arquivo centraliza configurações reutilizáveis

// URL base da API
export const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

// Thresholds padrão para todos os testes
export const DEFAULT_THRESHOLDS = {
  // 95% das requisições devem completar em menos de 500ms
  'http_req_duration': ['p(95)<500'],
  
  // 99% das requisições devem completar em menos de 1000ms
  'http_req_duration{expected_response:true}': ['p(99)<1000'],
  
  // Taxa de erro deve ser menor que 1%
  'http_req_failed': ['rate<0.01'],
  
  // Checks devem passar em 95% dos casos
  'checks': ['rate>0.95'],
};

// Configurações de stages comuns
export const SMOKE_STAGES = [
  { duration: '30s', target: 1 },  // Warmup
  { duration: '1m', target: 1 },   // Teste estável
];

export const LOAD_STAGES = [
  { duration: '1m', target: 10 },   // Ramp up para 10 usuários
  { duration: '3m', target: 10 },   // Mantém 10 usuários
  { duration: '1m', target: 20 },   // Ramp up para 20 usuários
  { duration: '3m', target: 20 },   // Mantém 20 usuários
  { duration: '1m', target: 0 },    // Ramp down
];

export const STRESS_STAGES = [
  { duration: '1m', target: 10 },   // Warmup
  { duration: '2m', target: 50 },   // Aumenta carga
  { duration: '2m', target: 100 },  // Stress médio
  { duration: '2m', target: 200 },  // Stress alto
  { duration: '2m', target: 300 },  // Stress máximo
  { duration: '2m', target: 0 },    // Recovery
];

export const SPIKE_STAGES = [
  { duration: '1m', target: 10 },   // Carga normal
  { duration: '10s', target: 100 }, // SPIKE!
  { duration: '1m', target: 10 },   // Volta ao normal
  { duration: '10s', target: 100 }, // SPIKE novamente!
  { duration: '1m', target: 10 },   // Volta ao normal
  { duration: '1m', target: 0 },    // Ramp down
];

export const SOAK_STAGES = [
  { duration: '5m', target: 20 },   // Ramp up
  { duration: '30m', target: 20 },  // Mantém carga por longo período
  { duration: '5m', target: 0 },    // Ramp down
];

// Headers padrão
export const DEFAULT_HEADERS = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

// Dados de teste
export const TEST_USER = {
  nome: 'Usuario Teste k6',
  email: `teste-${Date.now()}@qa.com.br`,
  password: 'teste123',
  administrador: 'true',
};

export const TEST_PRODUCT = {
  nome: 'Produto Teste k6',
  preco: 100,
  descricao: 'Produto para teste de carga',
  quantidade: 1000,
};

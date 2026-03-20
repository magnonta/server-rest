// Configurações globais e constantes para os testes k6
// Este arquivo centraliza configurações reutilizáveis

// URL base da API
export const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

// Modo CI — stages mais curtos para pipelines (ativado com K6_CI=true)
const CI_MODE = __ENV.K6_CI === 'true';

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

// ---- Stages padrão (execução local / produção) ----

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

// ---- Stages CI — mais curtos, mantendo pressão suficiente pro HPA ----

const SMOKE_STAGES_CI = [
  { duration: '15s', target: 1 },   // Warmup rápido
  { duration: '30s', target: 1 },   // Teste estável
];

const LOAD_STAGES_CI = [
  { duration: '30s', target: 10 },  // Ramp up rápido
  { duration: '1m', target: 10 },   // Mantém 10 usuários
  { duration: '30s', target: 20 },  // Ramp up para 20
  { duration: '1m30s', target: 20 },// Mantém 20 usuários
  { duration: '30s', target: 0 },   // Ramp down rápido
];

const STRESS_STAGES_CI = [
  { duration: '30s', target: 10 },  // Warmup rápido
  { duration: '1m', target: 100 },  // Sobe direto a 100
  { duration: '1m30s', target: 200 },// Stress alto
  { duration: '1m30s', target: 300 },// Stress máximo (tempo suficiente pro HPA)
  { duration: '1m', target: 0 },    // Recovery
];

const SPIKE_STAGES_CI = [
  { duration: '30s', target: 10 },  // Carga normal
  { duration: '10s', target: 100 }, // SPIKE!
  { duration: '30s', target: 10 },  // Volta ao normal
  { duration: '10s', target: 100 }, // SPIKE novamente!
  { duration: '30s', target: 10 },  // Volta ao normal
  { duration: '30s', target: 0 },   // Ramp down
];

const SOAK_STAGES_CI = [
  { duration: '2m', target: 20 },   // Ramp up
  { duration: '10m', target: 20 },  // Período reduzido
  { duration: '2m', target: 0 },    // Ramp down
];

// ---- Seletor de stages ----

/**
 * Retorna os stages adequados ao ambiente (CI ou local).
 * Uso: getStages('load'), getStages('stress'), etc.
 */
export function getStages(type) {
  const stages = {
    smoke:  CI_MODE ? SMOKE_STAGES_CI  : SMOKE_STAGES,
    load:   CI_MODE ? LOAD_STAGES_CI   : LOAD_STAGES,
    stress: CI_MODE ? STRESS_STAGES_CI : STRESS_STAGES,
    spike:  CI_MODE ? SPIKE_STAGES_CI  : SPIKE_STAGES,
    soak:   CI_MODE ? SOAK_STAGES_CI   : SOAK_STAGES,
  };
  return stages[type] || stages.load;
}

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

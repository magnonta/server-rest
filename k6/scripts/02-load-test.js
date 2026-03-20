// Load Test
// Teste de carga normal - simula uso esperado em produção
// Aumenta gradualmente de 0 até 20 usuários
// Objetivo: Validar que o sistema aguenta carga normal
// Uso: k6 run k6/scripts/02-load-test.js

import { group, check, sleep } from 'k6';
import { BASE_URL, DEFAULT_THRESHOLDS, getStages } from '../modules/config.js';
import {
  criarUsuario,
  fazerLogin,
  listarProdutos,
  buscarProduto,
  criarProduto,
  thinkTime,
} from '../modules/serverest-api.js';

export const options = {
  stages: getStages('load'),
  thresholds: {
    ...DEFAULT_THRESHOLDS,
    // Durante load test, aceitamos tempos um pouco maiores
    'http_req_duration': ['p(95)<800'],
    'http_req_duration{expected_response:true}': ['p(99)<1500'],
  },
};

export default function () {
  let token;
  let userId;
  let productId;

  // Dados únicos para cada VU
  const timestamp = Date.now();
  const vuId = __VU;
  const iterationId = __ITER;
  
  const uniqueEmail = `user-${vuId}-${iterationId}-${timestamp}@loadtest.com`;
  const uniqueProductName = `Produto Load Test ${vuId}-${iterationId}`;

  // Grupo 1: Criação de usuário e login
  group('01 - Registro e Autenticação', () => {
    // Criar novo usuário
    const userData = {
      nome: `Usuario Load Test ${vuId}`,
      email: uniqueEmail,
      password: 'senha123',
      administrador: 'true',
    };
    
    const userResponse = criarUsuario(BASE_URL, userData);
    userId = userResponse.json('_id');
    
    thinkTime(1, 2);
    
    // Fazer login
    token = fazerLogin(BASE_URL, uniqueEmail, 'senha123');
    
    check(token, {
      'login bem sucedido': (t) => t !== undefined && t.length > 0,
    });
  });

  thinkTime(2, 3);

  // Grupo 2: Navegação de produtos
  group('02 - Navegação de Produtos', () => {
    // Listar produtos
    const productsResponse = listarProdutos(BASE_URL);
    const products = productsResponse.json('produtos');
    
    thinkTime(1, 2);
    
    // Se existirem produtos, buscar detalhes de um aleatório
    if (products && products.length > 0) {
      const randomProduct = products[Math.floor(Math.random() * products.length)];
      buscarProduto(BASE_URL, randomProduct._id);
    }
  });

  thinkTime(2, 4);

  // Grupo 3: Criação de produto (apenas admin)
  group('03 - Criação de Produto', () => {
    const productData = {
      nome: uniqueProductName,
      preco: Math.floor(Math.random() * 1000) + 100,
      descricao: 'Produto criado durante teste de carga',
      quantidade: Math.floor(Math.random() * 100) + 10,
    };
    
    const productResponse = criarProduto(BASE_URL, token, productData);
    productId = productResponse.json('_id');
    
    check(productResponse, {
      'produto criado com sucesso': (r) => r.status === 201,
      'produto tem ID': (r) => r.json('_id') !== undefined,
    });
  });

  thinkTime(1, 2);
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'k6/results/load-test-summary.json': JSON.stringify(data),
    'k6/results/load-test-summary.html': htmlReport(data),
  };
}

import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';
import { htmlReport } from 'https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js';

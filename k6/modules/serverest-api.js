// Funções auxiliares para interagir com a API ServeRest
import http from 'k6/http';
import { check, sleep } from 'k6';
import { DEFAULT_HEADERS } from './config.js';

/**
 * Cria um novo usuário
 * @param {string} baseUrl - URL base da API
 * @param {object} userData - Dados do usuário
 * @returns {object} - Resposta da API
 */
export function criarUsuario(baseUrl, userData) {
  const response = http.post(
    `${baseUrl}/usuarios`,
    JSON.stringify(userData),
    { headers: DEFAULT_HEADERS }
  );
  
  check(response, {
    'criar usuário: status 201': (r) => r.status === 201,
    'criar usuário: tem _id': (r) => r.json('_id') !== undefined,
  });
  
  return response;
}

/**
 * Faz login e retorna o token
 * @param {string} baseUrl - URL base da API
 * @param {string} email - Email do usuário
 * @param {string} password - Senha do usuário
 * @returns {string} - Token de autorização
 */
export function fazerLogin(baseUrl, email, password) {
  const response = http.post(
    `${baseUrl}/login`,
    JSON.stringify({ email, password }),
    { headers: DEFAULT_HEADERS }
  );
  
  check(response, {
    'login: status 200': (r) => r.status === 200,
    'login: tem authorization': (r) => r.json('authorization') !== undefined,
  });
  
  return response.json('authorization');
}

/**
 * Lista todos os usuários
 * @param {string} baseUrl - URL base da API
 * @returns {object} - Resposta da API
 */
export function listarUsuarios(baseUrl) {
  const response = http.get(`${baseUrl}/usuarios`);
  
  check(response, {
    'listar usuários: status 200': (r) => r.status === 200,
    'listar usuários: tem array': (r) => Array.isArray(r.json('usuarios')),
  });
  
  return response;
}

/**
 * Busca um usuário por ID
 * @param {string} baseUrl - URL base da API
 * @param {string} id - ID do usuário
 * @returns {object} - Resposta da API
 */
export function buscarUsuario(baseUrl, id) {
  const response = http.get(`${baseUrl}/usuarios/${id}`);
  
  check(response, {
    'buscar usuário: status 200': (r) => r.status === 200,
  });
  
  return response;
}

/**
 * Cria um novo produto
 * @param {string} baseUrl - URL base da API
 * @param {string} token - Token de autorização
 * @param {object} productData - Dados do produto
 * @returns {object} - Resposta da API
 */
export function criarProduto(baseUrl, token, productData) {
  const headers = {
    ...DEFAULT_HEADERS,
    'Authorization': token,
  };
  
  const response = http.post(
    `${baseUrl}/produtos`,
    JSON.stringify(productData),
    { headers }
  );
  
  check(response, {
    'criar produto: status 201': (r) => r.status === 201,
    'criar produto: tem _id': (r) => r.json('_id') !== undefined,
  });
  
  return response;
}

/**
 * Lista todos os produtos
 * @param {string} baseUrl - URL base da API
 * @returns {object} - Resposta da API
 */
export function listarProdutos(baseUrl) {
  const response = http.get(`${baseUrl}/produtos`);
  
  check(response, {
    'listar produtos: status 200': (r) => r.status === 200,
    'listar produtos: tem array': (r) => Array.isArray(r.json('produtos')),
  });
  
  return response;
}

/**
 * Busca um produto por ID
 * @param {string} baseUrl - URL base da API
 * @param {string} id - ID do produto
 * @returns {object} - Resposta da API
 */
export function buscarProduto(baseUrl, id) {
  const response = http.get(`${baseUrl}/produtos/${id}`);
  
  check(response, {
    'buscar produto: status 200': (r) => r.status === 200,
  });
  
  return response;
}

/**
 * Cria um carrinho
 * @param {string} baseUrl - URL base da API
 * @param {string} token - Token de autorização
 * @param {array} produtos - Array de produtos [{idProduto, quantidade}]
 * @returns {object} - Resposta da API
 */
export function criarCarrinho(baseUrl, token, produtos) {
  const headers = {
    ...DEFAULT_HEADERS,
    'Authorization': token,
  };
  
  const response = http.post(
    `${baseUrl}/carrinhos`,
    JSON.stringify({ produtos }),
    { headers }
  );
  
  check(response, {
    'criar carrinho: status 201': (r) => r.status === 201,
  });
  
  return response;
}

/**
 * Conclui uma compra
 * @param {string} baseUrl - URL base da API
 * @param {string} token - Token de autorização
 * @returns {object} - Resposta da API
 */
export function concluirCompra(baseUrl, token) {
  const headers = {
    ...DEFAULT_HEADERS,
    'Authorization': token,
  };
  
  const response = http.del(
    `${baseUrl}/carrinhos/concluir-compra`,
    null,
    { headers }
  );
  
  check(response, {
    'concluir compra: status 200': (r) => r.status === 200,
  });
  
  return response;
}

/**
 * Função de think time (simula tempo de reflexão do usuário)
 * @param {number} min - Tempo mínimo em segundos
 * @param {number} max - Tempo máximo em segundos
 */
export function thinkTime(min = 1, max = 3) {
  const time = Math.random() * (max - min) + min;
  sleep(time);
}

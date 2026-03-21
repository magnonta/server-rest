// Funções auxiliares para interagir com a API ServeRest
import http from 'k6/http';
import { check, sleep } from 'k6';
import { DEFAULT_HEADERS } from './config.js';

// ============================================================================
// USUÁRIOS
// ============================================================================

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
    'criar usuário: tem _id': (r) => r.status !== 0 && r.json('_id') !== undefined,
  });
  
  return response;
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
    'listar usuários: tem array': (r) => r.status !== 0 && Array.isArray(r.json('usuarios')),
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
 * Edita um usuário existente (ou cria se não existir - upsert)
 * @param {string} baseUrl - URL base da API
 * @param {string} id - ID do usuário
 * @param {object} userData - Dados do usuário
 * @returns {object} - Resposta da API
 */
export function editarUsuario(baseUrl, id, userData) {
  const response = http.put(
    `${baseUrl}/usuarios/${id}`,
    JSON.stringify(userData),
    { headers: DEFAULT_HEADERS }
  );
  
  check(response, {
    'editar usuário: status 200': (r) => r.status === 200,
  });
  
  return response;
}

/**
 * Deleta um usuário por ID
 * @param {string} baseUrl - URL base da API
 * @param {string} id - ID do usuário
 * @returns {object} - Resposta da API
 */
export function deletarUsuario(baseUrl, id) {
  const response = http.del(`${baseUrl}/usuarios/${id}`);
  
  check(response, {
    'deletar usuário: status 200': (r) => r.status === 200,
  });
  
  return response;
}

// ============================================================================
// LOGIN
// ============================================================================

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
    'login: tem authorization': (r) => r.status !== 0 && r.json('authorization') !== undefined,
  });
  
  return response.status !== 0 ? response.json('authorization') : '';
}

// ============================================================================
// PRODUTOS
// ============================================================================

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
    'criar produto: tem _id': (r) => r.status !== 0 && r.json('_id') !== undefined,
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
    'listar produtos: tem array': (r) => r.status !== 0 && Array.isArray(r.json('produtos')),
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
 * Edita um produto existente (ou cria se não existir - upsert)
 * @param {string} baseUrl - URL base da API
 * @param {string} token - Token de autorização
 * @param {string} id - ID do produto
 * @param {object} productData - Dados do produto
 * @returns {object} - Resposta da API
 */
export function editarProduto(baseUrl, token, id, productData) {
  const headers = {
    ...DEFAULT_HEADERS,
    'Authorization': token,
  };
  
  const response = http.put(
    `${baseUrl}/produtos/${id}`,
    JSON.stringify(productData),
    { headers }
  );
  
  check(response, {
    'editar produto: status 200': (r) => r.status === 200,
  });
  
  return response;
}

/**
 * Deleta um produto por ID
 * @param {string} baseUrl - URL base da API
 * @param {string} token - Token de autorização
 * @param {string} id - ID do produto
 * @returns {object} - Resposta da API
 */
export function deletarProduto(baseUrl, token, id) {
  const headers = {
    ...DEFAULT_HEADERS,
    'Authorization': token,
  };
  
  const response = http.del(`${baseUrl}/produtos/${id}`, null, { headers });
  
  check(response, {
    'deletar produto: status 200': (r) => r.status === 200,
  });
  
  return response;
}

// ============================================================================
// CARRINHOS
// ============================================================================

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
 * Lista todos os carrinhos
 * @param {string} baseUrl - URL base da API
 * @returns {object} - Resposta da API
 */
export function listarCarrinhos(baseUrl) {
  const response = http.get(`${baseUrl}/carrinhos`);
  
  check(response, {
    'listar carrinhos: status 200': (r) => r.status === 200,
    'listar carrinhos: tem array': (r) => r.status !== 0 && Array.isArray(r.json('carrinhos')),
  });
  
  return response;
}

/**
 * Busca um carrinho por ID
 * @param {string} baseUrl - URL base da API
 * @param {string} id - ID do carrinho
 * @returns {object} - Resposta da API
 */
export function buscarCarrinho(baseUrl, id) {
  const response = http.get(`${baseUrl}/carrinhos/${id}`);
  
  check(response, {
    'buscar carrinho: status 200': (r) => r.status === 200,
  });
  
  return response;
}

/**
 * Conclui uma compra (deleta carrinho, estoque NÃO volta)
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
 * Cancela uma compra (deleta carrinho, estoque É reabastecido)
 * @param {string} baseUrl - URL base da API
 * @param {string} token - Token de autorização
 * @returns {object} - Resposta da API
 */
export function cancelarCompra(baseUrl, token) {
  const headers = {
    ...DEFAULT_HEADERS,
    'Authorization': token,
  };
  
  const response = http.del(
    `${baseUrl}/carrinhos/cancelar-compra`,
    null,
    { headers }
  );
  
  check(response, {
    'cancelar compra: status 200': (r) => r.status === 200,
  });
  
  return response;
}

// ============================================================================
// UTILITÁRIOS
// ============================================================================

/**
 * Função de think time (simula tempo de reflexão do usuário)
 * @param {number} min - Tempo mínimo em segundos
 * @param {number} max - Tempo máximo em segundos
 */
export function thinkTime(min = 1, max = 3) {
  const time = Math.random() * (max - min) + min;
  sleep(time);
}

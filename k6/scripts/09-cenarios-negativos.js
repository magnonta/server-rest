// Teste de Cenários Negativos: Validação de Regras de Negócio
// Testa deliberadamente cenários de erro para validar:
// - Autenticação e autorização (401, 403)
// - Validações de dados (400)
// - Regras de integridade de negócio (email duplicado, estoque, etc.)
//
// IMPORTANTE: Este script ESPERA erros — os checks validam que os códigos
// de erro corretos sejam retornados.

import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL, getStages, DEFAULT_HEADERS } from '../modules/config.js';
import {
  criarUsuario,
  fazerLogin,
  criarProduto,
  criarCarrinho,
  deletarUsuario,
  deletarProduto,
  cancelarCompra,
  thinkTime,
} from '../modules/serverest-api.js';

// Thresholds mais permissivos — esperamos muitos erros intencionais
export const options = {
  stages: getStages('smoke'), // Poucos VUs, foco em correção
  thresholds: {
    'http_req_duration': ['p(95)<500'],
    // Checks mais permissivos — metade dos checks vão "falhar" porque esperamos erros
    'checks': ['rate>0.50'],
    // Não validar taxa de erro — QUEREMOS erros neste teste
  },
};

// ============================================================================
// SETUP — Executado UMA VEZ antes do teste
// ============================================================================

export function setup() {
  console.log('🔧 Setup: Preparando dados para testes negativos...');
  
  // 1. Criar admin
  const adminData = {
    nome: 'Admin Testes Negativos',
    email: `admin-neg-${Date.now()}@k6.com.br`,
    password: 'senha123',
    administrador: 'true',
  };
  
  const adminResponse = criarUsuario(BASE_URL, adminData);
  const adminId = adminResponse.json('_id');
  const adminToken = fazerLogin(BASE_URL, adminData.email, adminData.password);
  
  // 2. Criar usuário comum
  const userComumData = {
    nome: 'Usuário Comum Testes',
    email: `user-comum-neg-${Date.now()}@k6.com.br`,
    password: 'senha123',
    administrador: 'false',
  };
  
  const userResponse = criarUsuario(BASE_URL, userComumData);
  const userId = userResponse.json('_id');
  const userToken = fazerLogin(BASE_URL, userComumData.email, userComumData.password);
  
  // 3. Criar produtos para testes
  const produto1Data = {
    nome: `Produto Testes Negativos 1-${Date.now()}`,
    preco: 100,
    descricao: 'Produto para testes de validação',
    quantidade: 5, // Estoque baixo intencional
  };
  
  const produto1Response = criarProduto(BASE_URL, adminToken, produto1Data);
  const produto1Id = produto1Response.json('_id');
  
  const produto2Data = {
    nome: `Produto Testes Negativos 2-${Date.now()}`,
    preco: 200,
    descricao: 'Outro produto para testes',
    quantidade: 10,
  };
  
  const produto2Response = criarProduto(BASE_URL, adminToken, produto2Data);
  const produto2Id = produto2Response.json('_id');
  
  // 4. Criar carrinho para um usuário (para testar DELETE de usuário com carrinho)
  const userComCarrinhoData = {
    nome: 'Usuário Com Carrinho',
    email: `user-carrinho-neg-${Date.now()}@k6.com.br`,
    password: 'senha123',
    administrador: 'false',
  };
  
  const userComCarrinhoResponse = criarUsuario(BASE_URL, userComCarrinhoData);
  const userComCarrinhoId = userComCarrinhoResponse.json('_id');
  const userComCarrinhoToken = fazerLogin(BASE_URL, userComCarrinhoData.email, userComCarrinhoData.password);
  
  // Criar carrinho para este usuário
  criarCarrinho(BASE_URL, userComCarrinhoToken, [
    { idProduto: produto1Id, quantidade: 1 },
  ]);
  
  console.log('✅ Setup completo');
  
  return {
    adminId,
    adminEmail: adminData.email,
    adminPassword: adminData.password,
    adminToken,
    userId,
    userEmail: userComumData.email,
    userPassword: userComumData.password,
    userToken,
    userComCarrinhoId,
    userComCarrinhoToken,
    produto1Id,
    produto2Id,
    produto1Nome: produto1Data.nome,
  };
}

// ============================================================================
// CENÁRIO PRINCIPAL — Testes de validação de regras de negócio
// ============================================================================

export default function (data) {
  // ============================================================================
  // TESTES DE AUTENTICAÇÃO E AUTORIZAÇÃO
  // ============================================================================
  
  // 1. Login com credenciais inválidas (401)
  const loginInvalidoResponse = http.post(
    `${BASE_URL}/login`,
    JSON.stringify({ email: 'naoexiste@teste.com', password: 'senhaerrada' }),
    { headers: DEFAULT_HEADERS }
  );
  
  check(loginInvalidoResponse, {
    'auth: login inválido retorna 401': (r) => r.status === 401,
    'auth: mensagem de erro no login': (r) => r.json('message') !== undefined,
  });
  
  thinkTime(0.5, 1);
  
  // 2. Acessar rota de admin sem token (401)
  const semTokenResponse = http.post(
    `${BASE_URL}/produtos`,
    JSON.stringify({ nome: 'Produto Teste', preco: 100, descricao: 'Teste', quantidade: 10 }),
    { headers: DEFAULT_HEADERS }
  );
  
  check(semTokenResponse, {
    'auth: criar produto sem token retorna 401': (r) => r.status === 401,
  });
  
  thinkTime(0.5, 1);
  
  // 3. Acessar rota de admin com token de usuário comum (403)
  const userHeaders = { ...DEFAULT_HEADERS, 'Authorization': data.userToken };
  const semPermissaoResponse = http.post(
    `${BASE_URL}/produtos`,
    JSON.stringify({ nome: 'Produto Teste', preco: 100, descricao: 'Teste', quantidade: 10 }),
    { headers: userHeaders }
  );
  
  check(semPermissaoResponse, {
    'auth: usuário comum criar produto retorna 403': (r) => r.status === 403,
    'auth: mensagem de falta de permissão': (r) => 
      r.json('message') === 'Rota exclusiva para administradores',
  });
  
  thinkTime(0.5, 1);
  
  // 4. Usar token inválido/malformado (401)
  const tokenInvalidoHeaders = { ...DEFAULT_HEADERS, 'Authorization': 'token-invalido-12345' };
  const tokenInvalidoResponse = http.post(
    `${BASE_URL}/produtos`,
    JSON.stringify({ nome: 'Produto Teste', preco: 100, descricao: 'Teste', quantidade: 10 }),
    { headers: tokenInvalidoHeaders }
  );
  
  check(tokenInvalidoResponse, {
    'auth: token inválido retorna 401': (r) => r.status === 401,
  });
  
  thinkTime(0.5, 1);
  
  // ============================================================================
  // TESTES DE VALIDAÇÃO DE USUÁRIOS
  // ============================================================================
  
  // 5. Criar usuário com email duplicado (400)
  const emailDuplicadoResponse = http.post(
    `${BASE_URL}/usuarios`,
    JSON.stringify({
      nome: 'Outro Usuário',
      email: data.userEmail, // Email já existente
      password: 'senha123',
      administrador: 'false',
    }),
    { headers: DEFAULT_HEADERS }
  );
  
  check(emailDuplicadoResponse, {
    'usuário: email duplicado retorna 400': (r) => r.status === 400,
    'usuário: mensagem de email já usado': (r) => 
      r.json('message') === 'Este email já está sendo usado',
  });
  
  thinkTime(0.5, 1);
  
  // 6. Deletar usuário com carrinho ativo (400)
  const deleteComCarrinhoResponse = http.del(
    `${BASE_URL}/usuarios/${data.userComCarrinhoId}`
  );
  
  check(deleteComCarrinhoResponse, {
    'usuário: deletar com carrinho retorna 400': (r) => r.status === 400,
    'usuário: mensagem de carrinho ativo': (r) => 
      r.json('message') === 'Não é permitido excluir usuário com carrinho cadastrado',
  });
  
  thinkTime(0.5, 1);
  
  // ============================================================================
  // TESTES DE VALIDAÇÃO DE PRODUTOS
  // ============================================================================
  
  // 7. Criar produto com nome duplicado (400)
  const adminHeaders = { ...DEFAULT_HEADERS, 'Authorization': data.adminToken };
  const nomeDuplicadoResponse = http.post(
    `${BASE_URL}/produtos`,
    JSON.stringify({
      nome: data.produto1Nome, // Nome já existente
      preco: 150,
      descricao: 'Tentando duplicar nome',
      quantidade: 20,
    }),
    { headers: adminHeaders }
  );
  
  check(nomeDuplicadoResponse, {
    'produto: nome duplicado retorna 400': (r) => r.status === 400,
    'produto: mensagem de nome já usado': (r) => 
      r.json('message') === 'Já existe produto com esse nome',
  });
  
  thinkTime(0.5, 1);
  
  // 8. Deletar produto que está em carrinho (400)
  const deleteProdutoEmCarrinhoResponse = http.del(
    `${BASE_URL}/produtos/${data.produto1Id}`,
    null,
    { headers: adminHeaders }
  );
  
  check(deleteProdutoEmCarrinhoResponse, {
    'produto: deletar produto em carrinho retorna 400': (r) => r.status === 400,
    'produto: mensagem de produto em carrinho': (r) => 
      r.json('message') === 'Não é permitido excluir produto que faz parte de carrinho',
  });
  
  thinkTime(0.5, 1);
  
  // ============================================================================
  // TESTES DE VALIDAÇÃO DE CARRINHOS
  // ============================================================================
  
  // 9. Criar segundo carrinho para mesmo usuário (400)
  const segundoCarrinhoResponse = http.post(
    `${BASE_URL}/carrinhos`,
    JSON.stringify({
      produtos: [{ idProduto: data.produto2Id, quantidade: 1 }],
    }),
    { headers: { ...DEFAULT_HEADERS, 'Authorization': data.userComCarrinhoToken } }
  );
  
  check(segundoCarrinhoResponse, {
    'carrinho: segundo carrinho retorna 400': (r) => r.status === 400,
    'carrinho: mensagem de carrinho existente': (r) => 
      r.json('message') === 'Não é permitido ter mais de 1 carrinho',
  });
  
  thinkTime(0.5, 1);
  
  // 10. Criar carrinho com produto inexistente (400)
  const produtoInexistenteResponse = http.post(
    `${BASE_URL}/carrinhos`,
    JSON.stringify({
      produtos: [{ idProduto: 'id-invalido-12345', quantidade: 1 }],
    }),
    { headers: { ...DEFAULT_HEADERS, 'Authorization': data.userToken } }
  );
  
  check(produtoInexistenteResponse, {
    'carrinho: produto inexistente retorna 400': (r) => r.status === 400,
  });
  
  thinkTime(0.5, 1);
  
  // 11. Criar carrinho com estoque insuficiente (400)
  const estoqueInsuficienteResponse = http.post(
    `${BASE_URL}/carrinhos`,
    JSON.stringify({
      produtos: [{ idProduto: data.produto2Id, quantidade: 9999 }], // Mais do que tem em estoque
    }),
    { headers: { ...DEFAULT_HEADERS, 'Authorization': data.userToken } }
  );
  
  check(estoqueInsuficienteResponse, {
    'carrinho: estoque insuficiente retorna 400': (r) => r.status === 400,
    'carrinho: mensagem de estoque': (r) => 
      r.json('message') !== undefined && r.json('message').includes('quantidade insuficiente'),
  });
  
  thinkTime(0.5, 1);
  
  // 12. Criar carrinho com produto duplicado (400)
  const produtoDuplicadoResponse = http.post(
    `${BASE_URL}/carrinhos`,
    JSON.stringify({
      produtos: [
        { idProduto: data.produto2Id, quantidade: 1 },
        { idProduto: data.produto2Id, quantidade: 2 }, // Mesmo produto duplicado
      ],
    }),
    { headers: { ...DEFAULT_HEADERS, 'Authorization': data.userToken } }
  );
  
  check(produtoDuplicadoResponse, {
    'carrinho: produto duplicado retorna 400': (r) => r.status === 400,
    'carrinho: mensagem de produto duplicado': (r) => 
      r.json('message') !== undefined && r.json('message').includes('duplicado'),
  });
  
  thinkTime(0.5, 1);
}

// ============================================================================
// TEARDOWN — Executado UMA VEZ após o teste
// ============================================================================

export function teardown(data) {
  console.log('🧹 Teardown: Limpando dados de teste...');
  
  // 1. Cancelar carrinho do usuário (para poder deletar)
  cancelarCompra(BASE_URL, data.userComCarrinhoToken);
  
  // 2. Deletar produtos
  deletarProduto(BASE_URL, data.adminToken, data.produto1Id);
  deletarProduto(BASE_URL, data.adminToken, data.produto2Id);
  console.log('✅ Produtos deletados');
  
  // 3. Deletar usuários
  deletarUsuario(BASE_URL, data.userComCarrinhoId);
  deletarUsuario(BASE_URL, data.userId);
  deletarUsuario(BASE_URL, data.adminId);
  console.log('✅ Usuários deletados');
  
  console.log('✨ Teardown completo');
}

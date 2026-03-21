// Teste de Fluxo: Jornada Completa do Comprador
// Simula o comportamento de um usuário realizando uma compra do início ao fim:
// - Criar conta
// - Fazer login
// - Navegar pelos produtos
// - Adicionar ao carrinho
// - Concluir compra

import { check } from 'k6';
import { BASE_URL, getStages, DEFAULT_THRESHOLDS } from '../modules/config.js';
import {
  criarUsuario,
  fazerLogin,
  listarProdutos,
  buscarProduto,
  criarCarrinho,
  concluirCompra,
  thinkTime,
  // Funções para setup/teardown
  criarProduto,
  deletarUsuario,
  deletarProduto,
  buscarUsuario,
} from '../modules/serverest-api.js';

export const options = {
  stages: getStages('fluxo'),
  thresholds: DEFAULT_THRESHOLDS,
};

// ============================================================================
// SETUP — Executado UMA VEZ antes do teste
// ============================================================================

export function setup() {
  console.log('🔧 Setup: Preparando ambiente de teste...');
  
  // 1. Criar usuário administrador para configurar produtos
  const adminData = {
    nome: 'Admin Fluxo Comprador',
    email: `admin-comprador-${Date.now()}@k6.com.br`,
    password: 'senha123',
    administrador: 'true',
  };
  
  const adminResponse = criarUsuario(BASE_URL, adminData);
  if (adminResponse.status !== 201) {
    throw new Error(`Falha ao criar admin: ${adminResponse.status}`);
  }
  
  const adminId = adminResponse.json('_id');
  const adminToken = fazerLogin(BASE_URL, adminData.email, adminData.password);
  
  console.log(`✅ Admin criado: ${adminId}`);
  
  // 2. Criar produtos com estoque suficiente
  const produtos = [];
  const produtosData = [
    { nome: 'Notebook Dell Inspiron 15', preco: 3500, descricao: 'Intel i7, 16GB RAM, 512GB SSD', quantidade: 100 },
    { nome: 'Mouse Logitech MX Master 3', preco: 450, descricao: 'Mouse ergonômico sem fio', quantidade: 200 },
    { nome: 'Teclado Mecânico Keychron K2', preco: 650, descricao: 'Switches Gateron Brown, wireless', quantidade: 150 },
    { nome: 'Monitor LG UltraWide 29"', preco: 1800, descricao: 'Full HD, IPS, 75Hz', quantidade: 80 },
    { nome: 'Webcam Logitech C920', preco: 550, descricao: 'Full HD 1080p, 30fps', quantidade: 120 },
  ];
  
  for (const produtoData of produtosData) {
    const produtoResponse = criarProduto(BASE_URL, adminToken, produtoData);
    if (produtoResponse.status === 201) {
      const produtoId = produtoResponse.json('_id');
      produtos.push({ id: produtoId, ...produtoData });
      console.log(`✅ Produto criado: ${produtoData.nome} (${produtoId})`);
    }
  }
  
  console.log(`🎯 Setup completo: ${produtos.length} produtos disponíveis`);
  
  return {
    adminId,
    adminEmail: adminData.email,
    adminPassword: adminData.password,
    produtos,
  };
}

// ============================================================================
// CENÁRIO PRINCIPAL — Executado por cada VU em loop
// ============================================================================

export default function (data) {
  // 1. CRIAR NOVA CONTA
  const userData = {
    nome: `Comprador ${__VU}-${__ITER}`,
    email: `comprador-${__VU}-${__ITER}-${Date.now()}@k6.com.br`,
    password: 'senha123',
    administrador: 'false',
  };
  
  const signupResponse = criarUsuario(BASE_URL, userData);
  check(signupResponse, {
    'registro: usuário criado': (r) => r.status === 201,
  });
  
  if (signupResponse.status !== 201) {
    console.error(`❌ VU ${__VU}: Falha no registro`);
    return;
  }
  
  const userId = signupResponse.json('_id');
  thinkTime(1, 2);
  
  // 2. FAZER LOGIN
  const token = fazerLogin(BASE_URL, userData.email, userData.password);
  check(token, {
    'login: token recebido': (t) => t && t.length > 0,
  });
  
  if (!token) {
    console.error(`❌ VU ${__VU}: Falha no login`);
    return;
  }
  
  thinkTime(2, 4);
  
  // 3. NAVEGAR PELOS PRODUTOS
  const produtosResponse = listarProdutos(BASE_URL);
  check(produtosResponse, {
    'navegação: produtos listados': (r) => r.status === 200,
    'navegação: tem produtos disponíveis': (r) => r.json('quantidade') > 0,
  });
  
  thinkTime(3, 5);
  
  // 4. VISUALIZAR PRODUTO ESPECÍFICO
  // Escolher produto aleatório da lista criada no setup
  const produtoEscolhido = data.produtos[Math.floor(Math.random() * data.produtos.length)];
  const produtoResponse = buscarProduto(BASE_URL, produtoEscolhido.id);
  check(produtoResponse, {
    'visualização: produto encontrado': (r) => r.status === 200,
    'visualização: produto tem estoque': (r) => r.json('quantidade') > 0,
  });
  
  thinkTime(4, 6);
  
  // 5. ADICIONAR AO CARRINHO
  const carrinhoProdutos = [
    {
      idProduto: produtoEscolhido.id,
      quantidade: Math.floor(Math.random() * 3) + 1, // 1 a 3 unidades
    },
  ];
  
  const carrinhoResponse = criarCarrinho(BASE_URL, token, carrinhoProdutos);
  check(carrinhoResponse, {
    'carrinho: criado com sucesso': (r) => r.status === 201,
  });
  
  if (carrinhoResponse.status !== 201) {
    console.error(`❌ VU ${__VU}: Falha ao criar carrinho`);
    return;
  }
  
  thinkTime(2, 4);
  
  // 6. CONCLUIR COMPRA
  const compraResponse = concluirCompra(BASE_URL, token);
  check(compraResponse, {
    'checkout: compra concluída': (r) => r.status === 200,
    'checkout: mensagem de sucesso': (r) => 
      r.json('message') === 'Registro excluído com sucesso',
  });
  
  // CLEANUP individual: deletar o usuário criado nesta iteração
  // (produtos são reutilizados entre VUs)
  deletarUsuario(BASE_URL, userId);
}

// ============================================================================
// TEARDOWN — Executado UMA VEZ após o teste
// ============================================================================

export function teardown(data) {
  console.log('🧹 Teardown: Limpando dados de teste...');
  
  // 1. Fazer login como admin para deletar produtos
  const adminToken = fazerLogin(BASE_URL, data.adminEmail, data.adminPassword);
  
  // 2. Deletar produtos criados no setup
  let produtosDeletados = 0;
  for (const produto of data.produtos) {
    const deleteResponse = deletarProduto(BASE_URL, adminToken, produto.id);
    if (deleteResponse.status === 200) {
      produtosDeletados++;
    }
  }
  
  console.log(`✅ ${produtosDeletados}/${data.produtos.length} produtos deletados`);
  
  // 3. Deletar usuário admin
  const adminDeleteResponse = deletarUsuario(BASE_URL, data.adminId);
  if (adminDeleteResponse.status === 200) {
    console.log('✅ Usuário admin deletado');
  }
  
  console.log('✨ Teardown completo');
}

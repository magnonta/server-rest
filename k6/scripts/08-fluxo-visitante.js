// Teste de Fluxo: Jornada do Visitante (Não Autenticado)
// Simula o comportamento de um visitante navegando pelo site sem fazer login:
// - Listar produtos disponíveis
// - Buscar produtos específicos
// - Visualizar informações de usuários
// - Explorar carrinhos públicos
// - Testar filtros de busca

import { check } from 'k6';
import { BASE_URL, getStages, DEFAULT_THRESHOLDS } from '../modules/config.js';
import {
  listarUsuarios,
  buscarUsuario,
  listarProdutos,
  buscarProduto,
  listarCarrinhos,
  buscarCarrinho,
  thinkTime,
  // Funções para setup/teardown
  criarUsuario,
  fazerLogin,
  criarProduto,
  deletarUsuario,
  deletarProduto,
} from '../modules/serverest-api.js';

export const options = {
  stages: getStages('fluxo'),
  thresholds: DEFAULT_THRESHOLDS,
};

// ============================================================================
// SETUP — Executado UMA VEZ antes do teste
// ============================================================================

export function setup() {
  console.log('🔧 Setup: Preparando dados de teste...');
  
  // 1. Criar admin para popular dados
  const adminData = {
    nome: 'Admin Fluxo Visitante',
    email: `admin-visitante-${Date.now()}@k6.com.br`,
    password: 'senha123',
    administrador: 'true',
  };
  
  const adminResponse = criarUsuario(BASE_URL, adminData);
  if (adminResponse.status !== 201) {
    throw new Error(`Falha ao criar admin: ${adminResponse.status}`);
  }
  
  const adminId = adminResponse.json('_id');
  const adminToken = fazerLogin(BASE_URL, adminData.email, adminData.password);
  
  // 2. Criar produtos para os visitantes navegarem
  const produtos = [];
  const produtosData = [
    { nome: 'iPhone 14 Pro', preco: 7500, descricao: '256GB, Preto', quantidade: 50 },
    { nome: 'Samsung Galaxy S23', preco: 5500, descricao: '128GB, Branco', quantidade: 60 },
    { nome: 'MacBook Pro M2', preco: 15000, descricao: '16GB RAM, 512GB SSD', quantidade: 30 },
    { nome: 'iPad Air 5', preco: 4500, descricao: '64GB, Wi-Fi', quantidade: 40 },
    { nome: 'AirPods Pro 2', preco: 2200, descricao: 'Com cancelamento de ruído', quantidade: 100 },
  ];
  
  for (const produtoData of produtosData) {
    const produtoResponse = criarProduto(BASE_URL, adminToken, produtoData);
    if (produtoResponse.status === 201) {
      const produtoId = produtoResponse.json('_id');
      produtos.push({ id: produtoId, ...produtoData });
    }
  }
  
  // 3. Criar alguns usuários comuns para os visitantes visualizarem
  const usuarios = [];
  const usuariosData = [
    { nome: 'Maria Silva', email: `maria-${Date.now()}@exemplo.com`, password: 'senha123', administrador: 'false' },
    { nome: 'João Santos', email: `joao-${Date.now()}@exemplo.com`, password: 'senha123', administrador: 'false' },
    { nome: 'Ana Costa', email: `ana-${Date.now()}@exemplo.com`, password: 'senha123', administrador: 'false' },
  ];
  
  for (const userData of usuariosData) {
    const userResponse = criarUsuario(BASE_URL, userData);
    if (userResponse.status === 201) {
      const userId = userResponse.json('_id');
      usuarios.push({ id: userId, ...userData });
    }
  }
  
  console.log(`✅ Setup completo: ${produtos.length} produtos, ${usuarios.length} usuários`);
  
  return {
    adminId,
    adminEmail: adminData.email,
    adminPassword: adminData.password,
    produtos,
    usuarios,
  };
}

// ============================================================================
// CENÁRIO PRINCIPAL — Executado por cada VU em loop
// ============================================================================

export default function (data) {
  // Visitante não faz login — apenas navegação pública
  
  // 1. LISTAR PRODUTOS (Landing page)
  const produtosResponse = listarProdutos(BASE_URL);
  check(produtosResponse, {
    'navegação: produtos listados': (r) => r.status === 200,
    'navegação: tem produtos disponíveis': (r) => r.json('quantidade') > 0,
    'navegação: array de produtos': (r) => Array.isArray(r.json('produtos')),
  });
  
  thinkTime(2, 4);
  
  // 2. VISUALIZAR PRODUTO ESPECÍFICO
  if (data.produtos.length > 0) {
    const produtoAleatorio = data.produtos[Math.floor(Math.random() * data.produtos.length)];
    const produtoResponse = buscarProduto(BASE_URL, produtoAleatorio.id);
    
    check(produtoResponse, {
      'produto: detalhes carregados': (r) => r.status === 200,
      'produto: tem nome': (r) => r.json('nome') !== undefined,
      'produto: tem preço': (r) => r.json('preco') !== undefined,
      'produto: tem estoque': (r) => r.json('quantidade') !== undefined,
    });
    
    thinkTime(3, 5);
  }
  
  // 3. BUSCAR PRODUTO COM FILTRO (pesquisa por nome)
  const termoPesquisa = ['iPhone', 'Samsung', 'MacBook', 'iPad', 'AirPods'][Math.floor(Math.random() * 5)];
  const buscaResponse = listarProdutos(BASE_URL);
  
  check(buscaResponse, {
    'busca: resultado retornado': (r) => r.status === 200,
  });
  
  thinkTime(2, 3);
  
  // 4. EXPLORAR LISTA DE USUÁRIOS (página "Sobre nós" ou "Equipe")
  const usuariosResponse = listarUsuarios(BASE_URL);
  check(usuariosResponse, {
    'usuários: listagem pública': (r) => r.status === 200,
    'usuários: tem registros': (r) => r.json('quantidade') > 0,
    'usuários: array de usuários': (r) => Array.isArray(r.json('usuarios')),
  });
  
  thinkTime(2, 4);
  
  // 5. VISUALIZAR PERFIL DE USUÁRIO
  if (data.usuarios.length > 0) {
    const usuarioAleatorio = data.usuarios[Math.floor(Math.random() * data.usuarios.length)];
    const usuarioResponse = buscarUsuario(BASE_URL, usuarioAleatorio.id);
    
    check(usuarioResponse, {
      'usuário: perfil carregado': (r) => r.status === 200,
      'usuário: tem nome': (r) => r.json('nome') !== undefined,
      'usuário: tem email': (r) => r.json('email') !== undefined,
    });
    
    thinkTime(1, 2);
  }
  
  // 6. EXPLORAR CARRINHOS PÚBLICOS (activity feed, últimas compras)
  const carrinhosResponse = listarCarrinhos(BASE_URL);
  check(carrinhosResponse, {
    'carrinhos: listagem pública': (r) => r.status === 200,
    'carrinhos: array de carrinhos': (r) => Array.isArray(r.json('carrinhos')),
  });
  
  // Se houver carrinhos, visualizar um deles
  if (carrinhosResponse.status === 200) {
    const carrinhos = carrinhosResponse.json('carrinhos');
    if (carrinhos && carrinhos.length > 0) {
      const carrinhoAleatorio = carrinhos[Math.floor(Math.random() * carrinhos.length)];
      const carrinhoResponse = buscarCarrinho(BASE_URL, carrinhoAleatorio._id);
      
      check(carrinhoResponse, {
        'carrinho: detalhes carregados': (r) => r.status === 200,
        'carrinho: tem produtos': (r) => Array.isArray(r.json('produtos')),
      });
      
      thinkTime(1, 2);
    }
  }
  
  thinkTime(2, 3);
  
  // 7. NAVEGAR ENTRE PÁGINAS (simulando paginação/navegação)
  listarProdutos(BASE_URL);
  thinkTime(1, 2);
  
  listarUsuarios(BASE_URL);
  thinkTime(1, 2);
}

// ============================================================================
// TEARDOWN — Executado UMA VEZ após o teste
// ============================================================================

export function teardown(data) {
  console.log('🧹 Teardown: Limpando dados de teste...');
  
  // 1. Fazer login como admin para deletar produtos
  const adminToken = fazerLogin(BASE_URL, data.adminEmail, data.adminPassword);
  
  // 2. Deletar produtos
  let produtosDeletados = 0;
  for (const produto of data.produtos) {
    const deleteResponse = deletarProduto(BASE_URL, adminToken, produto.id);
    if (deleteResponse.status === 200) {
      produtosDeletados++;
    }
  }
  
  console.log(`✅ ${produtosDeletados}/${data.produtos.length} produtos deletados`);
  
  // 3. Deletar usuários comuns
  let usuariosDeletados = 0;
  for (const usuario of data.usuarios) {
    const deleteResponse = deletarUsuario(BASE_URL, usuario.id);
    if (deleteResponse.status === 200) {
      usuariosDeletados++;
    }
  }
  
  console.log(`✅ ${usuariosDeletados}/${data.usuarios.length} usuários deletados`);
  
  // 4. Deletar admin
  const adminDeleteResponse = deletarUsuario(BASE_URL, data.adminId);
  if (adminDeleteResponse.status === 200) {
    console.log('✅ Admin deletado');
  }
  
  console.log('✨ Teardown completo');
}

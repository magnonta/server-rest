// Teste de Fluxo: Jornada Completa do Administrador
// Simula o comportamento de um administrador gerenciando o sistema:
// - Login como admin
// - Criar produtos (CRUD completo)
// - Editar produtos existentes
// - Gerenciar usuários
// - Deletar recursos

import { check } from 'k6';
import { BASE_URL, getStages, DEFAULT_THRESHOLDS } from '../modules/config.js';
import {
  criarUsuario,
  fazerLogin,
  listarUsuarios,
  buscarUsuario,
  editarUsuario,
  deletarUsuario,
  criarProduto,
  listarProdutos,
  buscarProduto,
  editarProduto,
  deletarProduto,
  thinkTime,
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
  
  // Criar usuário administrador base
  const adminData = {
    nome: 'Admin Principal',
    email: `admin-principal-${Date.now()}@k6.com.br`,
    password: 'senha123',
    administrador: 'true',
  };
  
  const adminResponse = criarUsuario(BASE_URL, adminData);
  if (adminResponse.status !== 201) {
    throw new Error(`Falha ao criar admin: ${adminResponse.status}`);
  }
  
  const adminId = adminResponse.json('_id');
  const adminToken = fazerLogin(BASE_URL, adminData.email, adminData.password);
  
  console.log(`✅ Admin base criado: ${adminId}`);
  console.log('🎯 Setup completo');
  
  return {
    adminId,
    adminEmail: adminData.email,
    adminPassword: adminData.password,
    adminToken,
  };
}

// ============================================================================
// CENÁRIO PRINCIPAL — Executado por cada VU em loop
// ============================================================================

export default function (data) {
  // 1. LOGIN COMO ADMINISTRADOR
  // Cada VU cria seu próprio admin para evitar conflitos de concorrência
  const adminData = {
    nome: `Admin ${__VU}-${__ITER}`,
    email: `admin-${__VU}-${__ITER}-${Date.now()}@k6.com.br`,
    password: 'senha123',
    administrador: 'true',
  };
  
  const signupResponse = criarUsuario(BASE_URL, adminData);
  check(signupResponse, {
    'setup admin: criado com sucesso': (r) => r.status === 201,
  });
  
  if (signupResponse.status !== 201) {
    console.error(`❌ VU ${__VU}: Falha ao criar admin`);
    return;
  }
  
  const adminId = signupResponse.json('_id');
  const token = fazerLogin(BASE_URL, adminData.email, adminData.password);
  
  check(token, {
    'login admin: token recebido': (t) => t && t.length > 0,
  });
  
  if (!token) {
    console.error(`❌ VU ${__VU}: Falha no login admin`);
    return;
  }
  
  thinkTime(1, 2);
  
  // 2. GERENCIAR PRODUTOS — CRUD COMPLETO
  
  // 2.1 Criar produto
  const novoProduto = {
    nome: `Produto Admin ${__VU}-${__ITER}-${Date.now()}`,
    preco: Math.floor(Math.random() * 1000) + 100,
    descricao: `Produto criado por admin VU ${__VU} iteração ${__ITER}`,
    quantidade: Math.floor(Math.random() * 100) + 50,
  };
  
  const produtoResponse = criarProduto(BASE_URL, token, novoProduto);
  check(produtoResponse, {
    'produto: criado com sucesso': (r) => r.status === 201,
    'produto: tem _id': (r) => r.json('_id') !== undefined,
  });
  
  if (produtoResponse.status !== 201) {
    console.error(`❌ VU ${__VU}: Falha ao criar produto`);
    deletarUsuario(BASE_URL, adminId);
    return;
  }
  
  const produtoId = produtoResponse.json('_id');
  thinkTime(1, 2);
  
  // 2.2 Listar produtos
  const listaProdutosResponse = listarProdutos(BASE_URL);
  check(listaProdutosResponse, {
    'produtos: listagem bem-sucedida': (r) => r.status === 200,
    'produtos: contém itens': (r) => r.json('quantidade') > 0,
  });
  
  thinkTime(1, 2);
  
  // 2.3 Buscar produto específico
  const buscarProdutoResponse = buscarProduto(BASE_URL, produtoId);
  check(buscarProdutoResponse, {
    'produto: busca bem-sucedida': (r) => r.status === 200,
    'produto: dados corretos': (r) => r.json('nome') === novoProduto.nome,
  });
  
  thinkTime(1, 2);
  
  // 2.4 Editar produto (atualizar preço e estoque)
  const produtoEditado = {
    ...novoProduto,
    preco: novoProduto.preco + 50,
    quantidade: novoProduto.quantidade + 20,
  };
  
  const editProdutoResponse = editarProduto(BASE_URL, token, produtoId, produtoEditado);
  check(editProdutoResponse, {
    'produto: edição bem-sucedida': (r) => r.status === 200,
    'produto: mensagem de sucesso': (r) => 
      r.json('message') === 'Registro alterado com sucesso',
  });
  
  thinkTime(1, 2);
  
  // 3. GERENCIAR USUÁRIOS
  
  // 3.1 Criar usuário comum
  const novoUsuario = {
    nome: `Usuário Teste ${__VU}-${__ITER}`,
    email: `usuario-teste-${__VU}-${__ITER}-${Date.now()}@k6.com.br`,
    password: 'senha123',
    administrador: 'false',
  };
  
  const usuarioResponse = criarUsuario(BASE_URL, novoUsuario);
  check(usuarioResponse, {
    'usuário: criado com sucesso': (r) => r.status === 201,
  });
  
  const usuarioId = usuarioResponse.status === 201 ? usuarioResponse.json('_id') : null;
  thinkTime(1, 2);
  
  // 3.2 Listar usuários
  const listaUsuariosResponse = listarUsuarios(BASE_URL);
  check(listaUsuariosResponse, {
    'usuários: listagem bem-sucedida': (r) => r.status === 200,
    'usuários: contém itens': (r) => r.json('quantidade') > 0,
  });
  
  thinkTime(1, 2);
  
  // 3.3 Buscar usuário específico
  if (usuarioId) {
    const buscarUsuarioResponse = buscarUsuario(BASE_URL, usuarioId);
    check(buscarUsuarioResponse, {
      'usuário: busca bem-sucedida': (r) => r.status === 200,
      'usuário: dados corretos': (r) => r.json('nome') === novoUsuario.nome,
    });
    
    thinkTime(1, 2);
  }
  
  // 3.4 Editar usuário (promover a admin)
  if (usuarioId) {
    const usuarioEditado = {
      ...novoUsuario,
      administrador: 'true',
    };
    
    const editUsuarioResponse = editarUsuario(BASE_URL, usuarioId, usuarioEditado);
    check(editUsuarioResponse, {
      'usuário: edição bem-sucedida': (r) => r.status === 200,
    });
    
    thinkTime(1, 2);
  }
  
  // 4. LIMPEZA — Deletar recursos criados nesta iteração
  
  // 4.1 Deletar produto
  const deleteProdutoResponse = deletarProduto(BASE_URL, token, produtoId);
  check(deleteProdutoResponse, {
    'produto: deleção bem-sucedida': (r) => r.status === 200,
  });
  
  // 4.2 Deletar usuário comum
  if (usuarioId) {
    const deleteUsuarioResponse = deletarUsuario(BASE_URL, usuarioId);
    check(deleteUsuarioResponse, {
      'usuário comum: deleção bem-sucedida': (r) => r.status === 200,
    });
  }
  
  // 4.3 Deletar admin usado nesta iteração
  deletarUsuario(BASE_URL, adminId);
}

// ============================================================================
// TEARDOWN — Executado UMA VEZ após o teste
// ============================================================================

export function teardown(data) {
  console.log('🧹 Teardown: Limpando dados de teste...');
  
  // Deletar admin base
  const adminDeleteResponse = deletarUsuario(BASE_URL, data.adminId);
  if (adminDeleteResponse.status === 200) {
    console.log('✅ Admin base deletado');
  }
  
  console.log('✨ Teardown completo');
}

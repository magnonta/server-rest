# Script PowerShell para instalar ferramentas necessárias
# Execute com privilégios de administrador
# Uso: .\install-tools-windows.ps1

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host " Instalação de Ferramentas - DevOps " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se está rodando como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Write-Host "Clique com botão direito no PowerShell e selecione 'Executar como Administrador'" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "✅ Executando como Administrador" -ForegroundColor Green
Write-Host ""

# Função para verificar se comando existe
function Test-Command {
    param($command)
    try {
        if (Get-Command $command -ErrorAction Stop) {
            return $true
        }
    }
    catch {
        return $false
    }
}

# Verificar e instalar Chocolatey
Write-Host "📦 Verificando Chocolatey..." -ForegroundColor Yellow
if (Test-Command choco) {
    Write-Host "✅ Chocolatey já está instalado" -ForegroundColor Green
} else {
    Write-Host "📥 Instalando Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    if (Test-Command choco) {
        Write-Host "✅ Chocolatey instalado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "❌ Falha ao instalar Chocolatey" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Instalar Git
Write-Host "📦 Verificando Git..." -ForegroundColor Yellow
if (Test-Command git) {
    $gitVersion = git --version
    Write-Host "✅ Git já está instalado: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "📥 Instalando Git..." -ForegroundColor Yellow
    choco install git -y
    refreshenv
    Write-Host "✅ Git instalado!" -ForegroundColor Green
}
Write-Host ""

# Instalar kubectl
Write-Host "📦 Verificando kubectl..." -ForegroundColor Yellow
if (Test-Command kubectl) {
    $kubectlVersion = kubectl version --client --short 2>$null
    Write-Host "✅ kubectl já está instalado: $kubectlVersion" -ForegroundColor Green
} else {
    Write-Host "📥 Instalando kubectl..." -ForegroundColor Yellow
    choco install kubernetes-cli -y
    refreshenv
    Write-Host "✅ kubectl instalado!" -ForegroundColor Green
}
Write-Host ""

# Instalar kind
Write-Host "📦 Verificando kind..." -ForegroundColor Yellow
if (Test-Command kind) {
    $kindVersion = kind version
    Write-Host "✅ kind já está instalado: $kindVersion" -ForegroundColor Green
} else {
    Write-Host "📥 Instalando kind..." -ForegroundColor Yellow
    choco install kind -y
    refreshenv
    Write-Host "✅ kind instalado!" -ForegroundColor Green
}
Write-Host ""

# Instalar k6
Write-Host "📦 Verificando k6..." -ForegroundColor Yellow
if (Test-Command k6) {
    $k6Version = k6 version
    Write-Host "✅ k6 já está instalado: $k6Version" -ForegroundColor Green
} else {
    Write-Host "📥 Instalando k6..." -ForegroundColor Yellow
    choco install k6 -y
    refreshenv
    Write-Host "✅ k6 instalado!" -ForegroundColor Green
}
Write-Host ""

# Instalar Node.js
Write-Host "📦 Verificando Node.js..." -ForegroundColor Yellow
if (Test-Command node) {
    $nodeVersion = node --version
    Write-Host "✅ Node.js já está instalado: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "📥 Instalando Node.js..." -ForegroundColor Yellow
    choco install nodejs -y
    refreshenv
    Write-Host "✅ Node.js instalado!" -ForegroundColor Green
}
Write-Host ""

# Verificar Docker Desktop
Write-Host "📦 Verificando Docker Desktop..." -ForegroundColor Yellow
if (Test-Command docker) {
    $dockerVersion = docker --version
    Write-Host "✅ Docker já está instalado: $dockerVersion" -ForegroundColor Green
    Write-Host "⚠️  Certifique-se que Docker Desktop está rodando!" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  Docker não encontrado!" -ForegroundColor Yellow
    Write-Host "📥 Por favor, baixe e instale Docker Desktop manualmente:" -ForegroundColor Yellow
    Write-Host "   https://www.docker.com/products/docker-desktop" -ForegroundColor Cyan
}
Write-Host ""

# Resumo
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "        Resumo da Instalação        " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$tools = @(
    @{Name="Chocolatey"; Command="choco"},
    @{Name="Git"; Command="git"},
    @{Name="kubectl"; Command="kubectl"},
    @{Name="kind"; Command="kind"},
    @{Name="k6"; Command="k6"},
    @{Name="Node.js"; Command="node"},
    @{Name="Docker"; Command="docker"}
)

foreach ($tool in $tools) {
    if (Test-Command $tool.Command) {
        Write-Host "✅ $($tool.Name)" -ForegroundColor Green
    } else {
        Write-Host "❌ $($tool.Name)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎉 Instalação concluída!" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  IMPORTANTE:" -ForegroundColor Yellow
Write-Host "1. Reinicie o PowerShell para garantir que todas as variáveis de ambiente sejam carregadas" -ForegroundColor White
Write-Host "2. Certifique-se que Docker Desktop está instalado e rodando" -ForegroundColor White
Write-Host "3. Execute .\verify-installation.ps1 para verificar tudo" -ForegroundColor White
Write-Host ""

pause

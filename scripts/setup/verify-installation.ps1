# Script PowerShell para verificar instalação das ferramentas
# Uso: .\verify-installation.ps1

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   Verificação de Ferramentas       " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$allOk = $true

# Função para testar comando e exibir versão
function Test-Tool {
    param(
        [string]$name,
        [string]$command,
        [string]$versionArg = "--version"
    )
    
    Write-Host "Verificando $name..." -ForegroundColor Yellow -NoNewline
    
    try {
        $version = & $command $versionArg 2>&1 | Select-Object -First 1
        Write-Host " ✅" -ForegroundColor Green
        Write-Host "  Versão: $version" -ForegroundColor Gray
        return $true
    }
    catch {
        Write-Host " ❌" -ForegroundColor Red
        Write-Host "  Não instalado ou não encontrado no PATH" -ForegroundColor Red
        return $false
    }
}

# Verificar ferramentas
$allOk = (Test-Tool "Git" "git") -and $allOk
$allOk = (Test-Tool "Docker" "docker") -and $allOk
$allOk = (Test-Tool "kubectl" "kubectl" "version --client --short") -and $allOk
$allOk = (Test-Tool "kind" "kind" "version") -and $allOk
$allOk = (Test-Tool "k6" "k6" "version") -and $allOk
$allOk = (Test-Tool "Node.js" "node") -and $allOk
$allOk = (Test-Tool "npm" "npm") -and $allOk

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan

# Verificações adicionais
Write-Host ""
Write-Host "Verificações adicionais:" -ForegroundColor Yellow
Write-Host ""

# Docker está rodando?
Write-Host "Docker está rodando?..." -ForegroundColor Yellow -NoNewline
try {
    docker ps | Out-Null
    Write-Host " ✅" -ForegroundColor Green
}
catch {
    Write-Host " ❌" -ForegroundColor Red
    Write-Host "  Docker Desktop não está rodando!" -ForegroundColor Red
    Write-Host "  Inicie o Docker Desktop e tente novamente" -ForegroundColor Yellow
    $allOk = $false
}

# Recursos do sistema
Write-Host ""
Write-Host "Recursos do sistema:" -ForegroundColor Yellow
$os = Get-CimInstance Win32_OperatingSystem
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$cpu = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors

Write-Host "  RAM Total: $totalRAM GB" -ForegroundColor Gray
Write-Host "  RAM Livre: $freeRAM GB" -ForegroundColor Gray
Write-Host "  CPUs: $cpu" -ForegroundColor Gray

if ($totalRAM -lt 8) {
    Write-Host "  ⚠️  Recomendado: mínimo 8GB RAM" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

if ($allOk) {
    Write-Host "🎉 Tudo certo! Você está pronto para as aulas!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Algumas ferramentas estão faltando ou não configuradas." -ForegroundColor Yellow
    Write-Host "   Execute install-tools-windows.ps1 como Administrador" -ForegroundColor Yellow
}

Write-Host ""
pause

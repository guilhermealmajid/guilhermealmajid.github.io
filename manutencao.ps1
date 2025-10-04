# =============================
# Otimização e Limpeza - Windows 11 Turbo
# =============================

function Remove-App {
    param([string]$PackageName)
    $app = Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue
    if ($app) {
        Write-Host "Removendo app: $PackageName" -ForegroundColor Yellow
        Remove-AppxPackage $app.PackageFullName
    } else {
        Write-Host "App $PackageName não encontrado." -ForegroundColor DarkGray
    }
}

function Debloat {
    Write-Host "Iniciando remoção de bloatware leve..." -ForegroundColor Green
    $appsToRemove = @(
        "*3dbuilder*",
        "*windowscommunicationsapps*",
        "*zunemusic*",
        "*zunevideo*",
        "*getstarted*",
        "*officehub*",
        "*people*",
        "*xboxapp*",
        "*solitairecollection*",
        "*skypeapp*",
        "*bingnews*",
        "*windowsalarms*",
        "*windowsfeedback*",
        "*windowsmaps*",
        "*yourphone*",
        "*messaging*"
    )
    foreach ($app in $appsToRemove) {
        Remove-App $app
    }
    Write-Host "Remoção concluída." -ForegroundColor Green
}

function Disable-Telemetry {
    Write-Host "Desativando telemetria básica..." -ForegroundColor Green
    $servicesToDisable = @("DiagTrack", "dmwappushservice")
    foreach ($service in $servicesToDisable) {
        if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
            Write-Host "Desativando serviço: $service" -ForegroundColor Yellow
            Set-Service -Name $service -StartupType Disabled
            Stop-Service -Name $service -Force
        }
    }
    Write-Host "Telemetria desativada." -ForegroundColor Green
}

function Apply-Tweaks {
    Write-Host "Aplicando tweaks de performance..." -ForegroundColor Green
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 26 -PropertyType DWORD -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "EnableBalloonTips" -Value 0 -Force
    Write-Host "Tweaks aplicados." -ForegroundColor Green
}

function Enable-WindowsUpdate {
    Write-Host "Garantindo que Windows Update está ativado..." -ForegroundColor Green
    Set-Service -Name "wuauserv" -StartupType Automatic
    Start-Service -Name "wuauserv"
    Write-Host "Windows Update ativado." -ForegroundColor Green
}

function Clear-WindowsUpdateCache {
    Write-Host "Limpando cache do Windows Update..." -ForegroundColor Green
    Stop-Service -Name wuauserv -Force
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv
    Write-Host "Cache do Windows Update limpo." -ForegroundColor Green
}

function Activate-Windows {
    Write-Host "Iniciando ativação do Windows..." -ForegroundColor Cyan
    try {
        irm https://get.activated.win | iex
        Write-Host "Ativação concluída com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "Falha na ativação. Verifique sua conexão e tente novamente." -ForegroundColor Red
    }
}

function Limpeza-Temporarios {
    Write-Host "Iniciando limpeza de arquivos temporários..." -ForegroundColor Green
    $caminhos = @(
        "$env:SystemRoot\Temp",
        "$env:SystemRoot\Prefetch",
        "$env:TEMP"
    )

    foreach ($caminho in $caminhos) {
        if (Test-Path $caminho) {
            Write-Host "Limpando: $caminho" -ForegroundColor Yellow
            try {
                Get-ChildItem -Path $caminho -Recurse -Force -ErrorAction SilentlyContinue |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Concluído: $caminho" -ForegroundColor DarkGray
            } catch {
                Write-Host "Erro ao limpar ${caminho}: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "Caminho não encontrado: $caminho" -ForegroundColor Red
        }
    }

    Write-Host "Limpeza concluída." -ForegroundColor Green
}

function Faxina-Geral {
    Debloat
    Disable-Telemetry
    Apply-Tweaks
    Limpeza-Temporarios
    Clear-WindowsUpdateCache
    Write-Host "Faxina completa finalizada!" -ForegroundColor Cyan
}

function Instalar-DriversSDI {
    Write-Host "Verificando e instalando drivers com SDI Origin..." -ForegroundColor Green

    $sdiFolder = "C:\SDI"
    $sdiExe = Join-Path $sdiFolder "SDIO_x64.exe"
    $sdiZipUrl = "https://sdi-tool.org/releases/SDIO_lite.zip"
    $sdiZip = "$sdiFolder\SDIO_lite.zip"

    # Cria pasta se necessário
    if (!(Test-Path $sdiFolder)) {
        New-Item -ItemType Directory -Path $sdiFolder | Out-Null
    }

    # Baixar SDI se não existir
    if (!(Test-Path $sdiExe)) {
        try {
            Write-Host "Baixando SDI Origin Lite..." -ForegroundColor Yellow

            # Forçar TLS 1.2 para compatibilidade
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            Invoke-WebRequest -Uri $sdiZipUrl -OutFile $sdiZip

            Write-Host "Extraindo arquivos..." -ForegroundColor Yellow
            Expand-Archive -Path $sdiZip -DestinationPath $sdiFolder -Force

            Remove-Item $sdiZip -Force
        } catch {
            Write-Host "Erro ao baixar ou extrair SDI: $($_.Exception.Message)" -ForegroundColor Red
            return
        }
    }

    # Executar instalação automática
    if (Test-Path $sdiExe) {
        Write-Host "Executando instalação automática de drivers..." -ForegroundColor Cyan
        Start-Process -FilePath $sdiExe -ArgumentList "/autoinstall /autoclose /norestorepoint" -Wait
        Write-Host "Drivers verificados e instalados." -ForegroundColor Green
    } else {
        Write-Host "SDI não encontrado após download. Verifique a extração." -ForegroundColor Red
    }
}

function MainMenu {
    Clear-Host
    Write-Host "===== Otimização e Limpeza - Windows 11 Turbo =====" -ForegroundColor Cyan
    Write-Host "1. Remover Bloatware Leve"
    Write-Host "2. Desativar Telemetria"
    Write-Host "3. Aplicar Tweaks de Performance"
    Write-Host "4. Ativar Windows Update"
    Write-Host "5. Limpar Cache do Windows Update"
    Write-Host "6. Ativar Windows (via script externo)"
    Write-Host "7. Limpar Arquivos Temporários"
    Write-Host "8. Executar Tudo (Faxina Geral)"
    Write-Host "9. Instalar Drivers com SDI Origin"
    Write-Host "10. Sair"
    $choice = Read-Host "Escolha uma opção (1-10)"
    switch ($choice) {
        "1" { Debloat; Pause; MainMenu }
        "2" { Disable-Telemetry; Pause; MainMenu }
        "3" { Apply-Tweaks; Pause; MainMenu }
        "4" { Enable-WindowsUpdate; Pause; MainMenu }
        "5" { Clear-WindowsUpdateCache; Pause; MainMenu }
        "6" { Activate-Windows; Pause; MainMenu }
        "7" { Limpeza-Temporarios; Pause; MainMenu }
        "8" { Faxina-Geral; Pause; MainMenu }
        "9" { Instalar-DriversSDI; Pause; MainMenu }
        "10" { Write-Host "Saindo..."; exit }
        default { Write-Host "Opção inválida. Tente novamente."; Pause; MainMenu }
    }
}

# Início do script
MainMenu

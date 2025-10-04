# Script personalizado para Windows 11 - Otimização para Trabalho e Performance
# Rodar via: irm https://seu-site.com/seu-script.ps1 | iex

function Remove-App {
    param([string]$PackageName)
    $app = Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue
    if ($app) {
        Write-Host "Removendo app: $PackageName" -ForegroundColor Yellow
        Remove-AppxPackage $app.PackageFullName
    }
    else {
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
        "*photos*",
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
    # Prioridade do agendador
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 26 -PropertyType DWORD -Force | Out-Null
    # Desativar animações
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Force
    # Desativar notificações e dicas
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
    }
    catch {
        Write-Host "Falha na ativação. Verifique sua conexão e tente novamente." -ForegroundColor Red
    }
}

function MainMenu {
    Clear-Host
    Write-Host "===== Otimização Windows 11 - Trabalho e Performance =====" -ForegroundColor Cyan
    Write-Host "1. Remover Bloatware Leve"
    Write-Host "2. Desativar Telemetria"
    Write-Host "3. Aplicar Tweaks de Performance"
    Write-Host "4. Ativar Windows Update"
    Write-Host "5. Limpar Cache do Windows Update"
    Write-Host "6. Ativar Windows (via script externo)"
    Write-Host "7. Sair"
    $choice = Read-Host "Escolha uma opção (1-7)"
    switch ($choice) {
        "1" { Debloat; Pause; MainMenu }
        "2" { Disable-Telemetry; Pause; MainMenu }
        "3" { Apply-Tweaks; Pause; MainMenu }
        "4" { Enable-WindowsUpdate; Pause; MainMenu }
        "5" { Clear-WindowsUpdateCache; Pause; MainMenu }
        "6" { Activate-Windows; Pause; MainMenu }
        "7" { Write-Host "Saindo..."; exit }
        default { Write-Host "Opção inválida. Tente novamente."; Pause; MainMenu }
    }
}

# Start the script
MainMenu

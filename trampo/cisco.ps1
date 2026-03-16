<#
.SYNOPSIS
    Automação ROMMON: Interrupção de Boot com Break estendido (1000ms) + Auto-Enter no PuTTY.
#>

# --- CONFIGURAÇÕES ---
$ComPort   = "COM3"
$PuttyPath = "C:\Program Files\PuTTY\putty.exe"
$BaudRate  = 9600

Clear-Host
Write-Host "--- AGUARDANDO BOOT DO EQUIPAMENTO (ROMMON) ---" -ForegroundColor Yellow
Write-Host "\---------------------------------------------/ " -ForegroundColor Yellow
Write-Host "  ### GUILHERME ALMEIDA (UBERLANDIA-MG) ###" -ForegroundColor Yellow
Write-Host " " -ForegroundColor black

# Limpa o PuTTY para liberar a porta COM
Get-Process putty -ErrorAction SilentlyContinue | Stop-Process -Force

$port = New-Object System.IO.Ports.SerialPort($ComPort, $BaudRate, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)

try {
    $port.ReadTimeout = 1000
    $port.Open()

    Write-Host "[OK] Porta $ComPort aberta. Aguardando saida do console..." -ForegroundColor Green
    Write-Host ">> LIGUE O ROTEADOR AGORA <<" -ForegroundColor Cyan -BackgroundColor DarkBlue

    $found = $false
    while (-not $found) {
        if ($port.BytesToRead -gt 0) {
            $data = $port.ReadExisting()
            Write-Host $data -NoNewline

            # Detecção de padrões de boot Cisco
            if ($data -match "ROMMON" -or $data -match "Bootstrap" -or $data -match "Read" -or $data -match "initialization") {
                Write-Host "`n`n[!] BOOT DETECTADO! ENVIANDO SEQUÊNCIA DE BREAK LONGA..." -ForegroundColor Green
                
                # --- LAÇO DE BREAK REFORMULADO (1000ms) ---
                for ($i = 1; $i -le 4; $i++) {
                    Write-Host "Enviando Break $i/4 (1000ms)..." -ForegroundColor Gray
                    $port.BreakState = $true
                    Start-Sleep -Milliseconds 1000  # Tempo de sinal aumentado conforme solicitado
                    $port.BreakState = $false
                    Start-Sleep -Milliseconds 500   # Intervalo entre sinais para o hardware processar
                }
                $found = $true
            }
        }
        Start-Sleep -Milliseconds 50
    }

    # Libera a porta para o PuTTY
    $port.Close()
    $port.Dispose()
    Start-Sleep -Seconds 1

    if (Test-Path $PuttyPath) {
        Write-Host "[!] Abrindo console PuTTY..." -ForegroundColor Green
        $puttyProc = Start-Process $PuttyPath -ArgumentList "-serial $ComPort -sercfg $BaudRate,8,n,1,N" -PassThru
    }

} catch {
    Write-Host "`n[ERRO FATAL]: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($puttyProc) {
        Write-Host "`n--- AGUARDANDO 4s PARA ENVIAR ENTER AO PUTTY ---" -ForegroundColor Gray
        Start-Sleep -Milliseconds 4000
        
        try {
            $wshell = New-Object -ComObject WScript.Shell
            # Foca a janela do PuTTY antes de mandar a tecla
            if ($wshell.AppActivate($puttyProc.Id)) {
                Start-Sleep -Milliseconds 500
                $wshell.SendKeys('~') # Envia o ENTER
				Start-Sleep -Milliseconds 3000
                $wshell.SendKeys('confreg 0x2142') # Envia o ENTER
				Start-Sleep -Milliseconds 500
                $wshell.SendKeys('~') # Envia o ENTER
				$wshell.SendKeys('reset') # Envia o ENTER
				Start-Sleep -Milliseconds 500
                $wshell.SendKeys('~') # Envia o ENTER
                Write-Host "[OK] Tecla ENTER enviada com sucesso!" -ForegroundColor Green
            }
        } catch {
            Write-Host "[!] Falha ao focar janela do PuTTY." -ForegroundColor Yellow
        }
    }

    Write-Host "`n--- PROCESSO CONCLUÍDO ---" -ForegroundColor Gray
    Read-Host "Pressione ENTER para fechar esta janela"
}
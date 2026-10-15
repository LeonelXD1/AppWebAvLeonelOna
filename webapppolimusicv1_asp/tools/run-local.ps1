<#
=====================================================================
 PoliMusic - Servidor de desarrollo local (IIS Express)
---------------------------------------------------------------------
 Levanta la aplicacion en http://localhost:8085/PoliMusic SIN necesidad
 de privilegios de administrador y sin tocar C:\inetpub.

 Que hace:
   1. Crea _test\PoliMusic como enlace (junction) a la carpeta
      PoliMusic, de modo que los cambios se reflejan al instante.
   2. Genera una configuracion propia de IIS Express que sirve _test
      como raiz del sitio en el puerto 8085.
   3. Arranca IIS Express en primer plano (Ctrl+C para detenerlo).

 Uso:
     powershell -ExecutionPolicy Bypass -File tools\run-local.ps1
=====================================================================
#>
[CmdletBinding()]
param(
    [int]$Port = 8085
)

$ErrorActionPreference = "Stop"
$Root    = Split-Path -Parent $PSScriptRoot
$AppDir  = Join-Path $Root "PoliMusic"
$TestDir = Join-Path $Root "_test"
$Link    = Join-Path $TestDir "PoliMusic"
$Conf    = Join-Path $PSScriptRoot "iisexpress.config"
$Logs    = Join-Path $PSScriptRoot "iislogs"

function Write-Step($m) { Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }

$IisExpress = @(
    "$env:ProgramFiles\IIS Express\iisexpress.exe",
    "${env:ProgramFiles(x86)}\IIS Express\iisexpress.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $IisExpress) {
    throw "No se encontro IIS Express. Instala 'IIS Express' (viene con Visual Studio) o usa tools\deploy-iis.ps1 sobre IIS completo."
}

Write-Step "Preparando el arbol de pruebas"
if (-not (Test-Path $TestDir)) { New-Item -ItemType Directory -Path $TestDir -Force | Out-Null }
if (Test-Path $Link) {
    $item = Get-Item $Link -Force
    if ($item.LinkType -eq "Junction") {
        Write-Ok "Enlace existente: $Link"
    } else {
        Remove-Item $Link -Recurse -Force
        New-Item -ItemType Junction -Path $Link -Target $AppDir | Out-Null
        Write-Ok "Enlace recreado"
    }
} else {
    New-Item -ItemType Junction -Path $Link -Target $AppDir | Out-Null
    Write-Ok "Enlace creado: $Link -> $AppDir"
}
if (-not (Test-Path $Logs)) { New-Item -ItemType Directory -Path $Logs -Force | Out-Null }

Write-Step "Generando la configuracion de IIS Express"
$template = Join-Path $env:USERPROFILE "Documents\IISExpress\config\applicationhost.config"
if (-not (Test-Path $template)) {
    throw "No se encontro la configuracion base de IIS Express en $template. Ejecuta IIS Express una vez para que la genere."
}
$cfg = Get-Content -Path $template -Raw -Encoding UTF8
$cfg = $cfg -replace 'name="WebSite1" id="1"', 'name="PoliMusicSite" id="1"'
$cfg = $cfg -replace 'physicalPath="%IIS_SITES_HOME%\\WebSite1"', ("physicalPath=" + [char]34 + $TestDir + [char]34)
$cfg = $cfg -replace 'bindingInformation=":8080:localhost"', ("bindingInformation=:" + $Port + ":localhost")
Set-Content -Path $Conf -Value $cfg -Encoding UTF8
Write-Ok "Configuracion escrita en tools\iisexpress.config"

Write-Step "Iniciando IIS Express"
Write-Host "  URL: http://localhost:$Port/PoliMusic/login.asp" -ForegroundColor Green
Write-Host "  Pulsa Ctrl+C para detener el servidor.`n" -ForegroundColor DarkGray

& $IisExpress /config:"$Conf" /systray:false

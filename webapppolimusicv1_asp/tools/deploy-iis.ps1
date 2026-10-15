<#
=====================================================================
 PoliMusic - Despliegue en IIS
---------------------------------------------------------------------
 Publica la aplicacion en C:\inetpub\wwwroot\PoliMusic, crea un grupo
 de aplicaciones dedicado y registra la aplicacion /PoliMusic en el
 sitio "Default Web Site".

 DEBE EJECUTARSE EN UNA CONSOLA DE POWERSHELL COMO ADMINISTRADOR:

     Click derecho en PowerShell -> Ejecutar como administrador
     cd C:\ruta\al\proyecto\PoliMusic
     Set-ExecutionPolicy -Scope Process Bypass -Force
     .\tools\deploy-iis.ps1

 Parametros opcionales:
     -Source   carpeta origen (por defecto, la carpeta padre de este script)
     -Site     nombre del sitio IIS   (por defecto "Default Web Site")
     -Vdir     nombre de la aplicacion (por defecto "PoliMusic")
     -Port     puerto del binding si el sitio no existe (por defecto 80)
=====================================================================
#>
[CmdletBinding()]
param(
    [string]$Source = (Join-Path (Split-Path -Parent $PSScriptRoot) "PoliMusic"),
    [string]$Site   = "Default Web Site",
    [string]$Vdir   = "PoliMusic",
    [int]   $Port   = 80
)

$ErrorActionPreference = "Stop"
$AppPoolName = "PoliMusicAppPool"
$Target      = Join-Path "C:\inetpub\wwwroot" $Vdir
$AppCmd      = "$env:windir\system32\inetsrv\appcmd.exe"

function Write-Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [!]  $msg" -ForegroundColor Yellow }

# ---------------------------------------------------------------------
# 0. Comprobaciones previas
# ---------------------------------------------------------------------
Write-Step "Comprobando privilegios y entorno"

$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Este script requiere privilegios de administrador. Abre PowerShell como administrador y vuelve a intentarlo."
}
Write-Ok "Ejecutando como administrador ($($identity.Name))"

if (-not (Test-Path $AppCmd)) {
    throw "No se encontro appcmd.exe. Instala el rol 'Servidor web (IIS)'."
}
Write-Ok "appcmd.exe disponible"

if (-not (Test-Path $Source)) {
    throw "No se encontro la carpeta de origen: $Source"
}
if (-not (Test-Path (Join-Path $Source "index.asp"))) {
    throw "La carpeta de origen no parece la aplicacion PoliMusic (falta index.asp): $Source"
}
Write-Ok "Origen valido: $Source"

# ---------------------------------------------------------------------
# 1. Rol ASP Clasico
# ---------------------------------------------------------------------
Write-Step "Verificando el modulo ASP Clasico"
$aspDll = "$env:windir\system32\inetsrv\asp.dll"
if (Test-Path $aspDll) {
    Write-Ok "asp.dll presente"
} else {
    Write-Warn "No se encontro asp.dll. Habilitando la caracteristica de Windows..."
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASP -All -NoRestart | Out-Null
    Write-Ok "Caracteristica IIS-ASP habilitada"
}

# ---------------------------------------------------------------------
# 2. Copia de archivos
# ---------------------------------------------------------------------
Write-Step "Publicando archivos en $Target"
if (-not (Test-Path "C:\inetpub\wwwroot")) {
    New-Item -ItemType Directory -Path "C:\inetpub\wwwroot" -Force | Out-Null
}
if (-not (Test-Path $Target)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
}

# Se excluye la carpeta SQL del contenido publicado opcionalmente; se copia
# igualmente porque web.config bloquea las peticiones a archivos .sql.
Copy-Item -Path (Join-Path $Source "*") -Destination $Target -Recurse -Force
$fileCount = (Get-ChildItem -Path $Target -Recurse -File | Measure-Object).Count
Write-Ok "$fileCount archivos publicados"

# Permisos de lectura para la identidad del grupo de aplicaciones
try {
    $acl = Get-Acl $Target
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "IIS AppPool\$AppPoolName", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($rule)
    Set-Acl -Path $Target -AclObject $acl
    Write-Ok "Permisos de lectura concedidos a IIS AppPool\$AppPoolName"
} catch {
    Write-Warn "No se pudieron ajustar los permisos: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------
# 3. Grupo de aplicaciones
# ---------------------------------------------------------------------
Write-Step "Configurando el grupo de aplicaciones '$AppPoolName'"
$existingPool = & $AppCmd list apppool "$AppPoolName" 2>$null
if ($LASTEXITCODE -ne 0 -or -not $existingPool) {
    & $AppCmd add apppool /name:"$AppPoolName" /managedRuntimeVersion:"" /managedPipelineMode:Integrated | Out-Null
    Write-Ok "Grupo de aplicaciones creado"
} else {
    Write-Ok "El grupo de aplicaciones ya existia"
}

# ASP Clasico: se establece a nivel de aplicacion (la seccion <asp> esta
# bloqueada para web.config, por eso se configura con appcmd).
& $AppCmd set config "$Site/$Vdir" /section:asp /scriptErrorSentToBrowser:true /commit:apphost | Out-Null
& $AppCmd set config "$Site/$Vdir" /section:asp /session:allowSessionState:true /commit:apphost | Out-Null
& $AppCmd set config "$Site/$Vdir" /section:asp /session:timeout:"00:30:00" /commit:apphost | Out-Null
Write-Ok "ASP configurado (sesiones de 30 min, errores detallados)"

# ---------------------------------------------------------------------
# 4. Sitio y aplicacion
# ---------------------------------------------------------------------
Write-Step "Registrando la aplicacion /$Vdir en el sitio '$Site'"
$siteExists = & $AppCmd list site "$Site" 2>$null
if (-not $siteExists) {
    Write-Warn "El sitio '$Site' no existe. Creandolo en el puerto $Port..."
    & $AppCmd add site /name:"$Site" /physicalPath:"C:\inetpub\wwwroot" /bindings:"http/*:$($Port):" | Out-Null
    Write-Ok "Sitio '$Site' creado"
}

$appPath = "$Site/$Vdir"
$appExists = & $AppCmd list app "$appPath" 2>$null
if ($appExists) {
    & $AppCmd set app "$appPath" /applicationPool:"$AppPoolName" | Out-Null
    Write-Ok "Aplicacion existente actualizada"
} else {
    & $AppCmd add app /site.name:"$Site" /path:"/$Vdir" /physicalPath:"$Target" | Out-Null
    & $AppCmd set app "$appPath" /applicationPool:"$AppPoolName" | Out-Null
    Write-Ok "Aplicacion /$Vdir creada"
}

# ---------------------------------------------------------------------
# 5. Arranque
# ---------------------------------------------------------------------
Write-Step "Iniciando servicios"
& $AppCmd start apppool "$AppPoolName" 2>$null | Out-Null
& $AppCmd start site "$Site" 2>$null | Out-Null
Write-Ok "Grupo de aplicaciones y sitio iniciados"

# ---------------------------------------------------------------------
# 6. Comprobacion
# ---------------------------------------------------------------------
Write-Step "Comprobando la publicacion"
$url = "http://localhost/$Vdir/login.asp"
try {
    $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20
    if ($resp.StatusCode -eq 200) {
        Write-Ok "La pagina de login responde correctamente (HTTP 200)"
    } else {
        Write-Warn "Respuesta inesperada: HTTP $($resp.StatusCode)"
    }
} catch {
    Write-Warn "No se pudo comprobar $url : $($_.Exception.Message)"
}

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host " Despliegue finalizado" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host " URL de la aplicacion : $url"
Write-Host " Carpeta publicada    : $Target"
Write-Host " Grupo de aplicaciones: $AppPoolName"
Write-Host ""
Write-Host " Cuentas de prueba:"
Write-Host "   Administrador     : userAdmin  / 12345678"
Write-Host "   Usuario estandar  : LeonelOna  / 123456789"
Write-Host ""
Write-Host " Recuerda que la base de datos BDD_PoliMusic debe existir y ser" -ForegroundColor Yellow
Write-Host " accesible con el login usr_polimusic (ver SQL\ en el proyecto)." -ForegroundColor Yellow
Write-Host ""

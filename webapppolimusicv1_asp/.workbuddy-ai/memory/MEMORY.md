# PoliMusic — notas de largo plazo del proyecto

## Contexto

Proyecto académico: clon de Spotify en **ASP Clásico (VBScript) + SQL Server**
sobre la base `BDD_PoliMusic`. Interfaz en **tonos azules** (sustituye el verde).
El código vive en `PoliMusic/` y se despliega en `C:\inetpub\wwwroot\PoliMusic`
con ruta virtual `/PoliMusic`.

## Convenciones del proyecto

- **Idioma**: código, comentarios, interfaz y documentación en **español sin
  tildes** (se evitan acentos en los archivos para no depender de la codificación
  de origen, aunque los .asp son UTF-8 con `@CODEPAGE 65001`).
- **Rutas de assets**: en la BD se guardan como rutas lógicas `~/songFiles/x.mp3`;
  `ResolveAsset()` las traduce a URL y comprueba existencia.
- **Acceso a datos**: siempre con `ADODB.Command` y parámetros. Nunca concatenar
  datos de usuario en SQL.
- **Salida HTML**: siempre por `H()` o `HAttr()`.
- **Formularios POST**: siempre con `CsrfField()` y `CsrfCheck()`.
- **Toda página** empieza con `<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>` y luego
  `<!--#include file="includes/app.asp"-->` (en `admin/` es
  `<!--#include virtual="/PoliMusic/includes/app.asp"-->`).
- **Antes de `includes/header.asp`** hay que asignar `PageTitle` y `ActiveNav`
  (no se declaran con `Dim` en el header para evitar "nombre redefinido").
- **`APP_VROOT`** en `includes/config.asp` es la única fuente de verdad de la ruta
  virtual; si cambia, hay que actualizar los `#include virtual` de `admin/`.

## Sistema de diseño (enfoque Apple)

- **CSS**: `assets/css/style.css`. Tokens en `:root` (tema claro), con el tema
  oscuro en `@media (prefers-color-scheme: dark) :root:not([data-theme="light"])`
  y en `:root[data-theme="dark"]` para la elección manual. El atributo se fija con
  un script en línea en el `<head>` (header.asp, login.asp, register.asp).
- **Nomenclatura**: BEM con modificadores de doble guion (`btn btn--primary`,
  `card__title`, `notice notice--danger`, `tag tag--accent`).
- **Iconos**: siempre con `Icon(nombre, tamano)` de `includes/ui.asp`. Nunca
  entidades HTML ni emoji. `EmptyState` recibe el nombre del icono.
- **Movimiento**: los muelles viven en `assets/js/spring.js` (`window.PM`).
  Regla: nada que el usuario pueda agarrar usa `transition`/`@keyframes`.
- **Preferencias del sistema**: hay bloques para `prefers-reduced-motion`,
  `prefers-reduced-transparency` y `prefers-contrast`. Mantenerlos al añadir CSS.
- **Espaciado y tamaños en `rem`** para que la interfaz escale con el tamaño de
  texto del usuario.

## Restricciones de VBScript que ya causaron errores (no repetir)

- Ninguna variable local puede llamarse igual que una función global
  (`Dim s` en `Function S`, `Dim h` en funciones que llaman a `H`).
- No usar `&` dentro de `Const` (usar `Dim` + asignación).
- No usar `_` para continuar línea dentro de `<%= ... %>`.
- **Un comentario `<%' ... %>` no puede ocupar dos líneas** (termina en el salto).
- Al añadir un parámetro a una función, hay que actualizar TODAS las llamadas:
  VBScript no admite argumentos opcionales de forma cómoda.
- ASP prohíbe `..` en `#include file` → usar `#include virtual`.
- `Server.MapPath("relativa")` se resuelve respecto a la carpeta de la página
  → usar `AssetsPath()`.
- **IIS Express cachea plantillas ASP compiladas**: hay que reiniciarlo tras
  cambiar includes. `pkill` no basta; usar `Stop-Process -Name iisexpress -Force`.

## Base de datos

9 tablas: `TBL_CATALOG`, `TBL_USER`, `TBL_SONG`, `TBL_ALBUM`, `TBL_TRACKLIST`,
`TBL_ARTIST`, `TBL_PLAYER`, `TBL_PLAYLIST`, `TBL_PLAYLIST_SONG`.
`USER_TYPE`: 0 = estándar, 1 = administrador. `TBL_PLAYLIST.TYPE`: 0 = pública,
1 = privada.

## Estado del entorno de la máquina

- SQL Server 2025 Express en `localhost,1433` (login `usr_polimusic` / `Politecnica1`).
- IIS 10 con ASP Clásico habilitado; `C:\inetpub\wwwroot` **requiere administrador**.
- IIS Express disponible para desarrollo local en el puerto 8085.
- Chrome instalado en `C:\Program Files\Google\Chrome\Application\chrome.exe`
  (usable con `puppeteer-core` para capturas).

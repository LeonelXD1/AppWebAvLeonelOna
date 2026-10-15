# PoliMusic — Clon de Spotify en ASP Clásico + SQL Server

Aplicación web de streaming musical con interfaz en **tonos azules** (sustituye el
verde característico de Spotify), autenticación completa y control de acceso por
perfiles sobre la base de datos `BDD_PoliMusic`.

---

## 1. Resumen técnico

| Elemento | Detalle |
|---|---|
| Servidor de aplicaciones | IIS 10 con **ASP Clásico** (VBScript) |
| Base de datos | SQL Server (`BDD_PoliMusic`, 9 tablas) |
| Conexión | OLE DB (`SQLOLEDB`) con `ADODB.Command` y parámetros |
| Front-end | HTML5 + CSS3 propio + JavaScript (reproductor persistente) |
| Ruta virtual | `/PoliMusic` (constante `APP_VROOT` en `includes/config.asp`) |
| Codificación | UTF-8 (`Response.CodePage = 65001`) |

---

## 2. Estructura de archivos

```
webapppolimusicv1_asp/
├── BDD_PoliMusic.sql                  Script original (UTF-16) entregado
├── SongFilesAndImages_resources/      Recursos multimedia originales
│
├── PoliMusic/                         ← ESTA carpeta se publica en IIS
│   ├── index.asp                      Enrutador de entrada (login / home)
│   ├── login.asp  register.asp  logout.asp
│   ├── home.asp                       Pantalla principal
│   ├── songs.asp  albums.asp  album.asp
│   ├── artists.asp  artist.asp  search.asp
│   ├── playlists.asp  playlist.asp  playlist_form.asp  playlist_add.asp
│   ├── profile.asp                    Perfil del usuario en sesión
│   ├── play.asp                       Endpoint que suma reproducciones
│   ├── web.config                     Configuración de IIS
│   ├── includes/
│   │   ├── config.asp                 Constantes, rutas y cadena de conexión
│   │   ├── db.asp                     Capa de datos (consultas parametrizadas)
│   │   ├── functions.asp              Saneamiento, rutas de assets, formato
│   │   ├── queries.asp                Fragmentos SQL reutilizables
│   │   ├── ui.asp                     Componentes de interfaz
│   │   ├── security.asp               Sesiones, roles y CSRF
│   │   ├── app.asp                    Arranque común (incluir siempre primero)
│   │   ├── header.asp / footer.asp    Plantillas y reproductor
│   ├── admin/                         Panel de administración
│   │   ├── index.asp  diagnostico.asp  nav.asp
│   │   ├── songs.asp  song_edit.asp
│   │   ├── albums.asp  album_edit.asp  album_track.asp
│   │   ├── artists.asp  artist_edit.asp
│   │   ├── playlists.asp  playlist_edit.asp  playlist_track.asp
│   │   └── users.asp  user_edit.asp
│   ├── assets/
│   │   ├── css/style.css              Sistema de diseno (claro y oscuro)
│   │   ├── js/spring.js               Motor de muelles y gestos
│   │   ├── js/app.js                  Reproductor, tema y control segmentado
│   │   ├── img/                       Placeholders y favicon
│   │   ├── songFiles/                 Pistas de audio
│   │   ├── albumImages/ artistImages/
│   │   ├── playlistImages/ userImages/
│   └── SQL/
│       ├── 01_BDD_PoliMusic.sql       Esquema + datos iniciales (UTF-8)
│       └── 02_leonelona_seed.sql      Usuario estándar LeonelOna
│
└── tools/                             Utilidades de desarrollo (NO se publican)
    ├── deploy-iis.ps1                 Despliegue en IIS (requiere admin)
    ├── run-local.ps1                  Servidor local con IIS Express
    ├── generate_assets.py             Genera imágenes y pistas de relleno
    ├── smoke.sh                       Prueba de humo HTTP
    └── screenshot.js                  Captura de pantallas (puppeteer-core)

_shots/                                Capturas de la interfaz ya generadas
_test/                                 Árbol de trabajo de IIS Express (junction)
```

### Scripts auxiliares

```bash
# Prueba de humo: recorre las paginas de cada perfil y reporta el codigo HTTP
bash tools/smoke.sh LeonelOna 123456789
bash tools/smoke.sh userAdmin 12345678

# Regenerar las imagenes de album/artista y las pistas de relleno
python tools/generate_assets.py

# Capturas de pantalla (requiere: npm install puppeteer-core)
node tools/screenshot.js userAdmin 12345678
```

---

## 3. Requisitos

- Windows 10/11 o Windows Server con **IIS** y el módulo **ASP Clásico** habilitado
  (`Panel de control → Programas → Activar características de Windows →
  Servidor web (IIS) → Desarrollo de aplicaciones → ASP`).
- **SQL Server** (probado con SQL Server 2025 Express) escuchando en `localhost,1433`
  con autenticación mixta.
- PowerShell 5.1 o superior para los scripts de despliegue.

---

## 4. Puesta en marcha

### 4.1 Base de datos

```powershell
# 1) Crear login, base de datos, tablas y datos iniciales
sqlcmd -S localhost,1433 -U sa -P <tu_clave_sa> -C -i PoliMusic\SQL\01_BDD_PoliMusic.sql

# 2) Crear el usuario estándar LeonelOna (idempotente)
sqlcmd -S localhost,1433 -U usr_polimusic -P Politecnica1 -C -d BDD_PoliMusic `
       -i PoliMusic\SQL\02_leonelona_seed.sql
```

> `01_BDD_PoliMusic.sql` **elimina y recrea** la base de datos `BDD_PoliMusic`.
> No lo ejecutes si ya tienes datos que quieras conservar.

### 4.2 Publicación en IIS

Abre **PowerShell como administrador** y ejecuta:

```powershell
cd <ruta-del-proyecto>
Set-ExecutionPolicy -Scope Process Bypass -Force
.\tools\deploy-iis.ps1
```

El script:

1. Comprueba privilegios y presencia de `asp.dll` (habilita la característica si falta).
2. Copia `PoliMusic\` a `C:\inetpub\wwwroot\PoliMusic`.
3. Crea el grupo de aplicaciones `PoliMusicAppPool` (sin código administrado, modo integrado).
4. Configura ASP (sesiones de 30 minutos, errores detallados) mediante `appcmd`,
   porque la sección `<asp>` está bloqueada para `web.config`.
5. Registra la aplicación `/PoliMusic` en *Default Web Site*.
6. Verifica que `http://localhost/PoliMusic/login.asp` responde.

**Acceso:** `http://localhost/PoliMusic/`

### 4.3 Entorno de desarrollo sin administrador

Si solo quieres probar sin tocar IIS:

```powershell
powershell -ExecutionPolicy Bypass -File tools\run-local.ps1
```

Levanta IIS Express en `http://localhost:8085/PoliMusic/` sirviendo la carpeta del
proyecto mediante un *junction*, de modo que los cambios se ven al instante.

---

## 5. Cuentas de prueba

| Perfil | Usuario | Contraseña | Origen |
|---|---|---|---|
| Administrador | `userAdmin` | `12345678` | Datos iniciales del script |
| Usuario estándar | `LeonelOna` | `123456789` | `02_leonelona_seed.sql` |
| Usuario estándar | `userNormal` | `12345678` | Datos iniciales del script |
| Usuario estándar | `username1` | `12345678` | Datos iniciales (contraseña en SHA-1) |

---

## 6. Control de acceso

### Administrador (`USER_TYPE = 1`)

Acceso completo a `admin/`:

- **Canciones**: alta, edición y baja. Al eliminar se limpian las relaciones
  (`TBL_TRACKLIST`, `TBL_PLAYER`, `TBL_PLAYLIST_SONG`).
- **Álbumes**: alta, edición, baja y gestión del *tracklist*.
- **Artistas**: alta, edición y baja.
- **Playlists**: gestión de las de cualquier usuario, incluida la reasignación
  de propietario y la gestión de canciones.
- **Usuarios**: alta, edición, cambio de perfil y baja.
- **Diagnóstico**: estado de la base de datos, del catálogo y de los archivos de audio.

### Usuario estándar (`USER_TYPE = 0`)

- Reproducción del catálogo completo y navegación por canciones, álbumes, artistas
  y playlists públicas.
- Búsqueda transversal.
- **Gestión exclusiva de sus propias playlists**: crear, editar, eliminar, añadir y
  quitar canciones.
- Edición de su propio perfil.

Las playlists privadas de otros usuarios no son visibles ni accesibles (redirección
con `err=denegado`). Todas las operaciones de escritura revalidan la propiedad en el
servidor; no basta con ocultar los botones en la interfaz.

---

## 7. Seguridad implementada

| Riesgo | Mitigación |
|---|---|
| **Inyección SQL** | 100 % de las consultas usan `ADODB.Command` con parámetros tipados. No existe concatenación de datos de usuario en SQL. |
| **XSS** | Toda salida pasa por `H()` (`Server.HTMLEncode`) o `HAttr()` para atributos. |
| **CSRF** | Token por sesión (`CsrfField()` / `CsrfCheck()`) en todos los formularios POST y en el endpoint de reproducciones. |
| **Fijación de sesión** | Se regenera `auth_token` y `csrf_token` al iniciar sesión; `IsAuthenticated()` exige token válido. |
| **Path traversal** | `ResolveAsset()` y `IsValidAssetPath()` rechazan `..` y solo admiten carpetas conocidas. |
| **Rutas de assets** | `AssetsPath()` usa rutas virtuales absolutas, evitando que `Server.MapPath` las resuelva respecto a la carpeta de la página. |
| **Cargas no verificadas** | Las rutas de imágenes se validan contra listas blancas construidas escaneando el sistema de archivos. |
| **Carpetas internas** | `web.config` oculta `includes/` y deniega la descarga de `.sql` y `.md`. |
| **Contraseñas** | Se almacenan como SHA-1 hexadecimal calculado por SQL Server (`HASHBYTES`). El login acepta además contraseñas heredadas en texto plano para no romper los datos iniciales. |
| **Cabeceras** | `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Cache-Control`. |

### Endurecimiento recomendado antes de producción

1. **Sacar la credencial de `includes/config.asp`**. Opciones: usar autenticación
   integrada de Windows en la cadena de conexión, o guardar la cadena en el
   `<connectionStrings>` de `applicationHost.config` / una variable de entorno.
2. Sustituir SHA-1 por un algoritmo con sal (bcrypt/Argon2) mediante un componente
   COM o cambiando el hash en `HASHBYTES`.
3. Servir el sitio por HTTPS y añadir HSTS.
4. Crear un login SQL con permisos mínimos en lugar de `db_owner`.
5. Desactivar `scriptErrorSentToBrowser` en producción.

---

## 8. Notas sobre los recursos multimedia

La carpeta `SongFilesAndImages_resources` entregada solo contiene:

- `SongFiles/bensound-adventure.mp3` (1 pista)
- `PlaylistImages/` (6 imágenes)
- `UserImages/default.jpg`, `UserImages/root.png`

Sin embargo, `BDD_PoliMusic.sql` referencia **5 pistas**, **5 portadas de álbum**,
**5 imágenes de artista** y un avatar adicional que no venían en la carpeta.

Para que la aplicación sea completamente funcional se hizo lo siguiente:

- Se **copiaron tal cual** los recursos reales a `PoliMusic/assets/`.
- Se **generaron** (con `tools/generate_assets.py`) las portadas de álbum, las
  imágenes de artista y los avatares que faltaban, en la misma paleta azul.
- Se **sintetizaron** las 4 pistas de audio ausentes (`Dreams`, `Energy`, `Scifi`,
  `Tomorrow`) como tonos de relleno para poder demostrar el flujo completo del
  reproductor. **Son placeholders**, no las canciones originales.

La aplicación detecta la ausencia de un archivo y muestra la pista marcada como
`sin audio` en lugar de fallar. `admin/diagnostico.asp` informa de cuántas pistas
están realmente disponibles.

Para usar los archivos definitivos, basta con dejarlos en
`PoliMusic/assets/songFiles/` con el nombre indicado en `TBL_SONG.SONG_PATH`.

---

## 9. Decisiones de diseño destacadas

**Capa de datos con parámetros con nombre traducidos a posicionales.**
El proveedor `SQLOLEDB` no admite parámetros con nombre en `adCmdText`, solo
marcadores `?`. Para no sacrificar la legibilidad del SQL, `BuildCommand()`
localiza cada marcador `@nombre`, valida que exista su parámetro y lo traduce a
`?` añadiendo los valores en el orden de aparición. Los valores viajan siempre
como parámetros tipados.

**Recordset desconectados.**
`DbOpen()` establece `CursorLocation = adUseClient`, de modo que `DbQuery()`
devuelve un `Recordset` desconectado y la conexión se cierra de inmediato.

**`SCOPE_IDENTITY()` en un único lote.**
`DbInsertReturnId()` envía el `INSERT` y la lectura del identificador en la misma
instrucción (`SET NOCOUNT ON; INSERT ...; SELECT CAST(SCOPE_IDENTITY() AS int)`),
porque `SCOPE_IDENTITY()` solo es válido dentro del mismo lote.

**Reproductor persistente.**
La cola, la pista actual y la posición se guardan en `sessionStorage`, por lo que
la música continúa al navegar entre páginas. El contador de reproducciones se
incrementa con una petición POST a `play.asp` (protegida por CSRF) la primera vez
que suena cada pista.

**Includes virtuales en `admin/`.**
ASP Clásico prohíbe `..` en las directivas `#include file`. Las páginas de
`admin/` usan `#include virtual="/PoliMusic/includes/..."`. Si cambias
`APP_VROOT`, debes actualizar también esas rutas.

**Restricciones de VBScript documentadas en el código.**
VBScript no distingue mayúsculas (una variable local no puede llamarse igual que
una función global) y no admite concatenación dentro de `Const`. Ambas
restricciones están resueltas y comentadas en `includes/functions.asp`,
`includes/queries.asp` y `includes/ui.asp`.

---

## 10. Esquema de la base de datos

| Tabla | Descripción |
|---|---|
| `TBL_CATALOG` | Catálogo de valores (tipos de usuario y de playlist) |
| `TBL_USER` | Usuarios: credenciales, perfil (`USER_TYPE`) y avatar |
| `TBL_SONG` | Canciones: nombre, ruta del archivo y contador de reproducciones |
| `TBL_ALBUM` | Álbumes: título, año y portada |
| `TBL_TRACKLIST` | Relación álbum ↔ canción |
| `TBL_ARTIST` | Artistas: nombre, apellido e imagen |
| `TBL_PLAYER` | Relación canción ↔ artista (varios artistas por canción) |
| `TBL_PLAYLIST` | Playlists: propietario, título, fecha, visibilidad y portada |
| `TBL_PLAYLIST_SONG` | Relación playlist ↔ canción |

Las rutas se almacenan en formato lógico (`~/songFiles/archivo.mp3`) y se traducen a
URLs reales con `ResolveAsset()`, que además comprueba la existencia del archivo sin
distinguir mayúsculas.

---

## 11. Comprobación rápida

```bash
bash tools/smoke.sh LeonelOna 123456789
bash tools/smoke.sh userAdmin 12345678
```

Recorre las páginas principales de cada perfil y reporta el código HTTP. Con el
perfil estándar, `/admin/*` debe responder `302` (acceso denegado).

---

## 12. Sistema de diseño (enfoque Apple)

La interfaz se rediseñó siguiendo los principios de *Designing Fluid Interfaces*
(WWDC 2018), *The Details of UI Typography* (WWDC 2020) y *Principles of Great
Design*. El resultado está en `assets/css/style.css` y `assets/js/spring.js`.

### Materiales y profundidad

La barra lateral, la barra superior y el reproductor son **capas translúcidas**
(`backdrop-filter` + fondo semitransparente) con el contenido pasando por debajo,
no barras opacas que consumen una franja fija. El material pesa según su función:
la barra lateral (estructural) es más opaca; el reproductor (interactivo) lleva un
borde luminoso superior que simula la luz rozando el cristal. El contenido se
desvanece con un degradado antes de encontrarse con el cromo — sin divisores de
1 px — y nunca se apila una superficie translúcida clara sobre otra.

### Tipografía

Pila de fuentes del sistema, escala en `rem` (escala con el tamaño de texto del
usuario) y **tracking específico por tamaño**: negativo en titulares
(`-0.03em` en el display), cercano a cero en el cuerpo. El interlineado va inverso
al tamaño: `1.05` en titulares, `1.47` en texto corrido. La jerarquía se construye
con peso + tamaño + interlineado como un conjunto, no solo con tamaño.

### Movimiento

`spring.js` implementa un muelle con los dos parámetros con los que Apple describe
el movimiento: **damping** (amortiguamiento) y **response** (rapidez, no duración).
Todos los muelles comparten un único `requestAnimationFrame`.

La propiedad que hace que la interfaz se sienta viva es la **interrumpibilidad**:
cada vez que cambia el objetivo, el muelle se re-engancha desde el valor y la
velocidad que tiene *en ese instante*, nunca desde el destino. Así una animación
puede agarrarse y revertirse a mitad de vuelo sin saltos ni discontinuidad de
velocidad.

Aplicaciones concretas:

| Interacción | Técnica |
|---|---|
| Pulsar cualquier botón | Escala en `:active` (CSS), en el mismo fotograma del `pointerdown` |
| Barra de progreso | Arrastre 1:1 con Pointer Capture, sin animación durante el gesto |
| Carrusel de álbumes | Arrastre 1:1 + banda elástica en los extremos + proyección de momento (`(v/1000)·d/(1−d)`, `d = 0.998`) y anclaje al punto proyectado |
| Indicador del control segmentado | Muelle crítico (damping 1.0, response 0.34) que "materializa" al cargar |
| Arranque de reproducción | Rebote sutil del botón (damping 0.6) como confirmación |

Se evitan `transition` y `@keyframes` en todo lo que el usuario puede agarrar; se
reservan para cambios de estado que no se tocan con el dedo (color, fondo, opacidad).

### Apariencia clara y oscura

El tema sigue la preferencia del sistema y puede fijarse manualmente desde el botón
del extremo derecho de la barra superior (se guarda en `localStorage`). El atributo
se aplica con un script en línea en el `<head>` para que no se vea el destello del
tema equivocado al cargar.

### Accesibilidad

- `prefers-reduced-motion: reduce` — los muelles pasan a críticos y muy cortos, y
  los desplazamientos se sustituyen por cambios de estado; el ecualizador se detiene.
- `prefers-reduced-transparency: reduce` — superficies sólidas y sin desenfoque.
- `prefers-contrast: more` — fondos opacos, bordes de 2 px y etiquetas reforzadas.
- Foco visible solo con teclado (`:focus-visible`), iconos con `aria-hidden` y
  controles con `aria-label`; atajos de teclado (espacio, `Mayús`+flechas).

### Iconografía

`Icon()` en `includes/ui.asp` genera un set de SVG dibujado sobre una rejilla de
24×24 con trazo uniforme de 1.7 px y extremos redondeados, de modo que todos los
iconos pesan visualmente lo mismo (el equivalente web de los símbolos del sistema).


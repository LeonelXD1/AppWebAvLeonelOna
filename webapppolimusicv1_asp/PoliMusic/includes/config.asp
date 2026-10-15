<%
' =====================================================================
'  PoliMusic - includes/config.asp
'  Configuracion central de la aplicacion: rutas, catalogos y conexion.
' =====================================================================

' --- Identidad de la aplicacion ---
Const APP_NAME    = "PoliMusic"
Const APP_TAGLINE = "Toda tu musica, en tonos azules"
Const APP_VERSION = "1.0.0"

' Ruta virtual de la aplicacion dentro de IIS (sin barra final).
' Si se publica en la raiz del sitio, dejar "".
Const APP_VROOT = "/PoliMusic"

' Carpeta de recursos multimedia, relativa a la raiz fisica de la app.
Const ASSETS_DIR = "assets"

' --- Tipos de usuario (TBL_USER.USER_TYPE) ---
Const USER_TYPE_STANDARD = 0
Const USER_TYPE_ADMIN    = 1

' --- Tipos de playlist (TBL_PLAYLIST.TYPE) ---
Const PLAYLIST_PUBLIC  = 0
Const PLAYLIST_PRIVATE = 1

' --- Parametros de sesion ---
Const SESSION_TIMEOUT_MIN = 30

' --- Longitudes maximas admitidas en formularios ---
Const LEN_USER     = 50
Const LEN_PASS     = 50
Const LEN_EMAIL    = 50
Const LEN_SONG     = 50
Const LEN_PATH     = 255
Const LEN_TITLE    = 50
Const LEN_ARTIST   = 100

' =====================================================================
'  Cadena de conexion a SQL Server
' ---------------------------------------------------------------------
'  Se respeta la cadena entregada por la institucion. Notas tecnicas:
'   * "Provider=SQLOLEDB" + "Initial Catalog" son necesarios para ADO.
'   * "Encrypt"/"TrustServerCertificate" son palabras clave de ODBC; el
'     proveedor OLE DB las ignora, por eso se define una variante de
'     respaldo (DB_CONNECTION_FALLBACK) sin ellas.
'   * En produccion la credencial debe salir de este archivo (ver
'     README-DEPLOY.md, apartado "Endurecimiento").
' =====================================================================
Const DB_CONNECTION = "Provider=SQLOLEDB;Data Source=localhost,1433;Initial Catalog=BDD_PoliMusic;User ID=usr_polimusic;Password=Politecnica1;Persist Security Info=True;Pooling=False;MultipleActiveResultSets=False;Encrypt=False;TrustServerCertificate=True;Application Name=""PoliMusic Web"";Command Timeout=0"

Const DB_CONNECTION_FALLBACK = "Provider=SQLOLEDB;Data Source=localhost,1433;Initial Catalog=BDD_PoliMusic;User ID=usr_polimusic;Password=Politecnica1;Persist Security Info=True;Application Name=""PoliMusic Web"""
%>

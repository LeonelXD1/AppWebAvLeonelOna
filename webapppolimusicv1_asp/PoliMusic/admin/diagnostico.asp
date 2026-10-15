<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include virtual="/PoliMusic/includes/app.asp"-->
<%
' =====================================================================
'  admin/diagnostico.asp - Comprobacion del entorno de despliegue
'  Solo accesible para administradores.
' =====================================================================
RequireAdmin()

Dim PageTitle, ActiveNav, AdminTab
PageTitle = "Diagnostico del sistema"
ActiveNav = "admin"
AdminTab = "diag"

Dim p, rs, dbOk, dbMsg
dbMsg = DbProbe()
dbOk  = (InStr(dbMsg, "ERROR") <> 1)
%>
<!--#include virtual="/PoliMusic/includes/header.asp"-->

<div class="page-head">
    <div>
        <h1>Diagnostico del sistema</h1>
        <p class="sub">Estado de la base de datos, del catalogo y de los archivos multimedia.</p>
    </div>
</div>

<!--#include file="nav.asp"-->

<div class="panel">
    <h2>Base de datos</h2>
    <table class="data">
        <tbody>
            <tr><th style="width:260px">Estado de la conexion</th>
                <td>
                    <% If dbOk Then %>
                        <span class="tag tag--accent">Conectada</span>
                    <% Else %>
                        <span class="tag tag--danger">Sin conexion</span>
                    <% End If %>
                    &nbsp;<%=H(dbMsg)%>
                </td></tr>
            <tr><th>Servidor / base</th><td><code>localhost,1433 / BDD_PoliMusic</code></td></tr>
            <tr><th>Usuario SQL</th><td><code>usr_polimusic</code></td></tr>
            <tr><th>Version del motor</th>
                <td><%=H(DbScalar("SELECT LEFT(@@VERSION, 60)", Nothing))%></td></tr>
            <tr><th>Ultimo error registrado</th>
                <td><%=H(IIf(LastDbError = "", "(ninguno)", LastDbError))%></td></tr>
        </tbody>
    </table>
</div>

<div class="panel">
    <h2>Contenido del catalogo</h2>
    <table class="data">
        <thead><tr><th>Entidad</th><th>Registros</th></tr></thead>
        <tbody>
            <tr><td>Usuarios</td><td><%=ToInt(DbScalar("SELECT COUNT(*) FROM TBL_USER", Nothing), 0)%></td></tr>
            <tr><td>Administradores</td><td><%=ToInt(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE USER_TYPE = 1", Nothing), 0)%></td></tr>
            <tr><td>Canciones</td><td><%=ToInt(DbScalar("SELECT COUNT(*) FROM TBL_SONG", Nothing), 0)%></td></tr>
            <tr><td>Albumes</td><td><%=ToInt(DbScalar("SELECT COUNT(*) FROM TBL_ALBUM", Nothing), 0)%></td></tr>
            <tr><td>Artistas</td><td><%=ToInt(DbScalar("SELECT COUNT(*) FROM TBL_ARTIST", Nothing), 0)%></td></tr>
            <tr><td>Playlists</td><td><%=ToInt(DbScalar("SELECT COUNT(*) FROM TBL_PLAYLIST", Nothing), 0)%></td></tr>
            <tr><td>Pistas en albumes</td><td><%=ToInt(DbScalar("SELECT COUNT(*) FROM TBL_TRACKLIST", Nothing), 0)%></td></tr>
            <tr><td>Canciones en playlists</td><td><%=ToInt(DbScalar("SELECT COUNT(*) FROM TBL_PLAYLIST_SONG", Nothing), 0)%></td></tr>
        </tbody>
    </table>
</div>

<div class="panel">
    <h2>Archivos de audio</h2>
    <p class="sub" style="margin-bottom:14px">Pistas referenciadas en la base de datos cuyo archivo no esta presente en <code>assets/songFiles</code>.</p>
    <%
    Set rs = DbQuery("SELECT ID_SONG, SONG_NAME, SONG_PATH FROM TBL_SONG ORDER BY SONG_NAME", Nothing)
    Dim missing, total
    missing = 0
    total = 0
    If Not (rs Is Nothing) Then
        Do While Not rs.EOF
            total = total + 1
            If SongUrl(rs("SONG_PATH")) = "" Then missing = missing + 1
            rs.MoveNext
        Loop
    End If
    %>
    <p><b><%=total - missing%></b> de <b><%=total%></b> pistas disponibles<% If missing > 0 Then %> &middot; <span class="tag tag--danger"><%=missing%> sin archivo</span><% End If %></p>
    <%
    If missing > 0 Then
        Response.Write "<div class=""table-wrap"" style=""margin-top:12px""><table class=""data""><thead><tr>" & _
                       "<th>#</th><th>Cancion</th><th>Ruta esperada</th><th>Estado</th></tr></thead><tbody>"
        Set p = New DbParams
        Set rs = DbQuery("SELECT ID_SONG, SONG_NAME, SONG_PATH FROM TBL_SONG ORDER BY SONG_NAME", Nothing)
        Dim n
        n = 0
        Do While Not rs.EOF
            n = n + 1
            Response.Write "<tr><td>" & n & "</td><td>" & H(rs("SONG_NAME")) & "</td>" & _
                           "<td><code>" & H(rs("SONG_PATH")) & "</code></td><td>"
            If SongUrl(rs("SONG_PATH")) = "" Then
                Response.Write "<span class=""tag tag--danger"">falta</span>"
            Else
                Response.Write "<span class=""tag tag--accent"">ok</span>"
            End If
            Response.Write "</td></tr>"
            rs.MoveNext
        Loop
        Response.Write "</tbody></table></div>"
    End If
    %>
</div>

<div class="panel">
    <h2>Entorno de ejecucion</h2>
    <table class="data">
        <tbody>
            <tr><th style="width:260px">Ruta virtual</th><td><code><%=H(APP_VROOT)%></code></td></tr>
            <tr><th>Version de la aplicacion</th><td><%=H(APP_VERSION)%></td></tr>
            <tr><th>Codificacion</th><td>UTF-8 (Response.CodePage = <%=Response.CodePage%>)</td></tr>
            <tr><th>Timeout de sesion</th><td><%=Session.Timeout%> minutos</td></tr>
            <tr><th>Sesion iniciada</th><td><%=H(Session("login_time") & "")%></td></tr>
            <tr><th>Ruta fisica de assets</th><td><code><%=H(AssetsPath(""))%></code></td></tr>
        </tbody>
    </table>
</div>

<!--#include virtual="/PoliMusic/includes/footer.asp"-->

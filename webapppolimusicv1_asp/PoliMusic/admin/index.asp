<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include virtual="/PoliMusic/includes/app.asp"-->
<%
' =====================================================================
'  admin/index.asp - Resumen del panel de administracion
' =====================================================================
RequireAdmin()

Dim PageTitle, ActiveNav, AdminTab
PageTitle = "Panel de administracion"
ActiveNav = "admin"
AdminTab = "index"

Dim rs, totalUsers, totalAdmins, totalSongs, totalAlbums, totalArtists, totalPlaylists, totalPlays
totalUsers     = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_USER", Nothing), 0)
totalAdmins    = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE USER_TYPE = " & USER_TYPE_ADMIN, Nothing), 0)
totalSongs     = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_SONG", Nothing), 0)
totalAlbums    = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_ALBUM", Nothing), 0)
totalArtists   = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_ARTIST", Nothing), 0)
totalPlaylists = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_PLAYLIST", Nothing), 0)
totalPlays     = ToInt(DbScalar("SELECT ISNULL(SUM(PLAYS), 0) FROM TBL_SONG", Nothing), 0)
%>
<!--#include virtual="/PoliMusic/includes/header.asp"-->

<div class="page-head">
    <div>
        <h1>Panel de administracion</h1>
        <p class="sub">Gestion completa del catalogo: canciones, albumes, artistas, playlists y usuarios.</p>
    </div>
    <div>
        <span class="tag tag--accent">Perfil administrador</span>
    </div>
</div>

<!--#include file="nav.asp"-->

<div class="stats">
    <div class="stat"><div class="k">Canciones</div><div class="v"><%=totalSongs%></div><div class="s"><%=totalPlays%> reproducciones</div></div>
    <div class="stat"><div class="k">Albumes</div><div class="v"><%=totalAlbums%></div><div class="s">en el catalogo</div></div>
    <div class="stat"><div class="k">Artistas</div><div class="v"><%=totalArtists%></div><div class="s">registrados</div></div>
    <div class="stat"><div class="k">Playlists</div><div class="v"><%=totalPlaylists%></div><div class="s">creadas</div></div>
    <div class="stat"><div class="k">Usuarios</div><div class="v"><%=totalUsers%></div><div class="s"><%=totalAdmins%> administradores</div></div>
</div>

<div class="section">
    <div class="section-head">
        <h2>Canciones mas reproducidas</h2>
        <a href="<%=APP_VROOT%>/admin/songs.asp">Gestionar</a>
    </div>
    <%
    Set rs = DbQuery(SqlSongs("", "s.PLAYS DESC, s.SONG_NAME"), Nothing)
    If rs Is Nothing Or rs.EOF Then
        Response.Write EmptyState("music", "Sin canciones", "El catalogo esta vacio.")
    Else
        Response.Write "<div class=""table-wrap""><table class=""data""><thead><tr>" & _
                       "<th>#</th><th>Cancion</th><th>Artistas</th><th>Album</th><th>Reproducciones</th>" & _
                       "</tr></thead><tbody>"
        Dim num
        num = 0
        Do While Not rs.EOF And num < 8
            num = num + 1
            Response.Write "<tr><td>" & num & "</td>" & _
                           "<td>" & H(rs("SONG_NAME")) & "</td>" & _
                           "<td>" & H(rs("ARTISTS")) & "</td>" & _
                           "<td>" & H(rs("ALBUM_TITLE") & "") & "</td>" & _
                           "<td>" & H(rs("PLAYS")) & "</td></tr>"
            rs.MoveNext
        Loop
        Response.Write "</tbody></table></div>"
    End If
    %>
</div>

<div class="section">
    <div class="section-head">
        <h2>Usuarios recientes</h2>
        <a href="<%=APP_VROOT%>/admin/users.asp">Gestionar</a>
    </div>
    <%
    Set rs = DbQuery("SELECT TOP 8 u.ID_USER, u.USERNAME, u.EMAIL, u.USER_TYPE, " & _
                     "(SELECT COUNT(*) FROM TBL_PLAYLIST p WHERE p.ID_USER = u.ID_USER) AS N " & _
                     "FROM TBL_USER u ORDER BY u.ID_USER DESC", Nothing)
    If rs Is Nothing Or rs.EOF Then
        Response.Write EmptyState("profile", "Sin usuarios", "No hay usuarios registrados.")
    Else
        Response.Write "<div class=""table-wrap""><table class=""data""><thead><tr>" & _
                       "<th>Usuario</th><th>Correo</th><th>Perfil</th><th>Playlists</th><th></th>" & _
                       "</tr></thead><tbody>"
        Do While Not rs.EOF
            Response.Write "<tr><td>" & H(rs("USERNAME")) & "</td>" & _
                           "<td>" & H(rs("EMAIL")) & "</td>" & _
                           "<td><span class=""badge " & _
                           IIf(CInt(rs("USER_TYPE")) = USER_TYPE_ADMIN, "badge-admin"">Administrador", "badge-user"">Usuario") & _
                           "</span></td>" & _
                           "<td>" & H(rs("N")) & "</td>" & _
                           "<td class=""actions""><a class=""btn btn--fill btn--sm"" href=""" & APP_VROOT & _
                           "/admin/user_edit.asp?id=" & rs("ID_USER") & """>Editar</a></td></tr>"
            rs.MoveNext
        Loop
        Response.Write "</tbody></table></div>"
    End If
    %>
</div>

<!--#include virtual="/PoliMusic/includes/footer.asp"-->

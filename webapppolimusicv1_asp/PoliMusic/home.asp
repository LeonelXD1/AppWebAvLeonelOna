<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  home.asp - Pantalla principal
' =====================================================================
RequireLogin()

Dim PageTitle, ActiveNav
PageTitle = "Inicio"
ActiveNav = "home"

Dim p, rs, greeting, hh
Dim totalSongs, totalAlbums, totalArtists, totalPlaylists, totalUsers

hh = Hour(Now())
If hh < 12 Then
    greeting = "Buenos dias"
ElseIf hh < 19 Then
    greeting = "Buenas tardes"
Else
    greeting = "Buenas noches"
End If

totalSongs     = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_SONG", Nothing), 0)
totalAlbums    = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_ALBUM", Nothing), 0)
totalArtists   = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_ARTIST", Nothing), 0)
totalPlaylists = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_PLAYLIST", Nothing), 0)
totalUsers     = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_USER", Nothing), 0)

Set p = New DbParams
p.Add "@u", adInteger, 0, CurrentUserId()
Set rs = DbQuery("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE ID_USER = @u", p)
Dim myPlaylists
myPlaylists = ToInt(rs(0), 0)
rs.Close
%>
<!--#include file="includes/header.asp"-->

<div class="page-head">
    <div>
        <h1 class="t-display"><%=H(greeting)%>,<br><%=H(CurrentUsername())%></h1>
        <p class="sub mt-4"><%=H(UserTypeName(CurrentUserType()))%> &middot; Explora el catalogo y arma tus playlists.</p>
    </div>
    <div class="row">
        <a class="btn btn--primary btn--lg" href="<%=APP_VROOT%>/songs.asp"><%=Icon("play", 17)%><span>Reproducir catalogo</span></a>
    </div>
</div>

<div class="stats">
    <div class="stat"><div class="k">Canciones</div><div class="v"><%=totalSongs%></div><div class="s">en el catalogo</div></div>
    <div class="stat"><div class="k">Albumes</div><div class="v"><%=totalAlbums%></div><div class="s">publicados</div></div>
    <div class="stat"><div class="k">Artistas</div><div class="v"><%=totalArtists%></div><div class="s">registrados</div></div>
    <div class="stat"><div class="k">Mis playlists</div><div class="v"><%=myPlaylists%></div><div class="s">de <%=totalPlaylists%> en total</div></div>
    <% If IsAdmin() Then %>
    <div class="stat"><div class="k">Usuarios</div><div class="v"><%=totalUsers%></div><div class="s">con acceso</div></div>
    <% End If %>
</div>

<!-- Canciones mas escuchadas -->
<div class="section">
    <div class="section-head">
        <h2>Las mas escuchadas</h2>
        <a href="<%=APP_VROOT%>/songs.asp">Ver todas</a>
    </div>
    <%
    Set rs = DbQuery(SqlSongs("", "s.PLAYS DESC, s.SONG_NAME"), Nothing)
    If rs Is Nothing Or rs.EOF Then
        Response.Write EmptyState("music", "Sin canciones", "El catalogo todavia esta vacio.")
    Else
        Response.Write "<div class=""tracklist"" data-queue>" & TrackHead()
        Dim n
        n = 0
        Do While Not rs.EOF And n < 5
            n = n + 1
            Response.Write SongRow(rs("ID_SONG"), rs("SONG_NAME"), rs("SONG_PATH"), rs("ARTISTS"), rs("ALBUM_IMAGE"), rs("PLAYS"), n, "")
            rs.MoveNext
        Loop
        Response.Write "</div>"
    End If
    %>
</div>

<!-- Albumes destacados -->
<div class="section">
    <div class="section-head">
        <h2>Albumes destacados</h2>
        <a href="<%=APP_VROOT%>/albums.asp">Ver todos</a>
    </div>
    <%
    Set rs = DbQuery("SELECT TOP 8 ID_ALBUM, TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH FROM TBL_ALBUM ORDER BY ID_ALBUM", Nothing)
    If rs Is Nothing Or rs.EOF Then
        Response.Write EmptyState("album", "Sin albumes", "No hay albumes registrados.")
    Else
        Response.Write "<div class=""carousel"" data-carousel>"
        Do While Not rs.EOF
            Response.Write CardAlbum(rs("ID_ALBUM"), rs("TITLE_ALBUM"), rs("RELEASE_YEAR"), rs("ALBUM_IMAGE_PATH"))
            rs.MoveNext
        Loop
        Response.Write "</div>"
    End If
    %>
</div>

<!-- Mis playlists -->
<div class="section">
    <div class="section-head">
        <h2>Mis playlists</h2>
        <a href="<%=APP_VROOT%>/playlists.asp">Administrar</a>
    </div>
    <%
    Set p = New DbParams
    p.Add "@u", adInteger, 0, CurrentUserId()
    Set rs = DbQuery("SELECT TOP 6 p.ID_PLAYLIST, p.TITLE, p.TYPE, p.PHOTO, u.USERNAME " & _
                     "FROM TBL_PLAYLIST p INNER JOIN TBL_USER u ON u.ID_USER = p.ID_USER " & _
                     "WHERE p.ID_USER = @u ORDER BY p.CREATION_DATE DESC, p.ID_PLAYLIST DESC", p)
    If rs Is Nothing Or rs.EOF Then
        Response.Write EmptyState("playlist", "Aun no tienes playlists", "Crea tu primera playlist desde la seccion Playlists.")
    Else
        Response.Write "<div class=""grid"">"
        Do While Not rs.EOF
            Response.Write CardPlaylist(rs("ID_PLAYLIST"), rs("TITLE"), rs("USERNAME"), PlaylistTypeName(rs("TYPE")), rs("PHOTO"))
            rs.MoveNext
        Loop
        Response.Write "</div>"
    End If
    %>
</div>

<!-- Artistas -->
<div class="section">
    <div class="section-head">
        <h2>Artistas</h2>
        <a href="<%=APP_VROOT%>/artists.asp">Ver todos</a>
    </div>
    <%
    Set rs = DbQuery("SELECT TOP 6 ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE FROM TBL_ARTIST ORDER BY ARTIST_NAME", Nothing)
    If rs Is Nothing Or rs.EOF Then
        Response.Write EmptyState("artist", "Sin artistas", "No hay artistas registrados.")
    Else
        Response.Write "<div class=""grid"">"
        Do While Not rs.EOF
            Response.Write CardArtist(rs("ID_ARTIST"), rs("ARTIST_NAME") & " " & rs("ARTIST_LASTNAME"), rs("ARTIST_IMAGE"))
            rs.MoveNext
        Loop
        Response.Write "</div>"
    End If
    %>
</div>

<!--#include file="includes/footer.asp"-->

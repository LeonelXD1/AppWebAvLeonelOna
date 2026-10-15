<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  playlists.asp - Listado de playlists
'   * Usuario estandar: ve las suyas y las publicas de los demas.
'   * Administrador: ve todas.
' =====================================================================
RequireLogin()

Dim PageTitle, ActiveNav
PageTitle = "Playlists"
ActiveNav = "playlists"

Dim p, rs, sql
%>
<!--#include file="includes/header.asp"-->

<div class="page-head">
    <div>
        <h1>Playlists</h1>
        <p class="sub">Crea, edita y organiza tu musica.</p>
    </div>
    <div>
        <a class="btn btn--primary" href="<%=APP_VROOT%>/playlist_form.asp">+ Nueva playlist</a>
    </div>
</div>

<!-- Mis playlists -->
<div class="section">
    <div class="section-head"><h2>Mis playlists</h2></div>
    <%
    Set p = New DbParams
    p.Add "@u", adInteger, 0, CurrentUserId()
    Set rs = DbQuery("SELECT p.ID_PLAYLIST, p.TITLE, p.TYPE, p.PHOTO, u.USERNAME, " & _
                     "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = p.ID_PLAYLIST) AS N " & _
                     "FROM TBL_PLAYLIST p INNER JOIN TBL_USER u ON u.ID_USER = p.ID_USER " & _
                     "WHERE p.ID_USER = @u ORDER BY p.CREATION_DATE DESC, p.ID_PLAYLIST DESC", p)
    If rs Is Nothing Or rs.EOF Then
        Response.Write EmptyState("playlist", "Aun no tienes playlists", "Pulsa en Nueva playlist para crear la primera.")
    Else
        Response.Write "<div class=""grid"">"
        Do While Not rs.EOF
            Response.Write CardPlaylist(rs("ID_PLAYLIST"), rs("TITLE"), rs("USERNAME"), _
                                        PlaylistTypeName(rs("TYPE")) & " - " & rs("N") & " canciones", rs("PHOTO"))
            rs.MoveNext
        Loop
        Response.Write "</div>"
    End If
    %>
</div>

<!-- Playlists publicas -->
<div class="section">
    <div class="section-head"><h2>Playlists publicas de la comunidad</h2></div>
    <%
    Set p = New DbParams
    p.Add "@u", adInteger, 0, CurrentUserId()
    Set rs = DbQuery("SELECT p.ID_PLAYLIST, p.TITLE, p.TYPE, p.PHOTO, u.USERNAME, " & _
                     "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = p.ID_PLAYLIST) AS N " & _
                     "FROM TBL_PLAYLIST p INNER JOIN TBL_USER u ON u.ID_USER = p.ID_USER " & _
                     "WHERE p.TYPE = " & PLAYLIST_PUBLIC & " AND p.ID_USER <> @u " & _
                     "ORDER BY p.CREATION_DATE DESC, p.ID_PLAYLIST DESC", p)
    If rs Is Nothing Or rs.EOF Then
        Response.Write EmptyState("globe", "Sin playlists publicas", "Nadie ha publicado playlists todavia.")
    Else
        Response.Write "<div class=""grid"">"
        Do While Not rs.EOF
            Response.Write CardPlaylist(rs("ID_PLAYLIST"), rs("TITLE"), rs("USERNAME"), _
                                        PlaylistTypeName(rs("TYPE")) & " - " & rs("N") & " canciones", rs("PHOTO"))
            rs.MoveNext
        Loop
        Response.Write "</div>"
    End If
    %>
</div>

<% If IsAdmin() Then %>
<!-- Todas las playlists (solo administrador) -->
<div class="section">
    <div class="section-head"><h2>Todas las playlists (administracion)</h2></div>
    <%
    Set rs = DbQuery("SELECT p.ID_PLAYLIST, p.TITLE, p.TYPE, p.PHOTO, u.USERNAME, " & _
                     "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = p.ID_PLAYLIST) AS N " & _
                     "FROM TBL_PLAYLIST p INNER JOIN TBL_USER u ON u.ID_USER = p.ID_USER " & _
                     "ORDER BY u.USERNAME, p.TITLE", Nothing)
    If rs Is Nothing Or rs.EOF Then
        Response.Write EmptyState("playlist", "Sin playlists", "No hay playlists registradas.")
    Else
        Response.Write "<div class=""grid"">"
        Do While Not rs.EOF
            Response.Write CardPlaylist(rs("ID_PLAYLIST"), rs("TITLE"), rs("USERNAME"), _
                                        PlaylistTypeName(rs("TYPE")) & " - " & rs("N") & " canciones", rs("PHOTO"))
            rs.MoveNext
        Loop
        Response.Write "</div>"
    End If
    %>
</div>
<% End If %>

<!--#include file="includes/footer.asp"-->

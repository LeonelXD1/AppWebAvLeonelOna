<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  search.asp - Busqueda transversal en el catalogo
' =====================================================================
RequireLogin()

Dim PageTitle, ActiveNav
PageTitle = "Buscar"
ActiveNav = "search"

Dim term, pat, p, rs, num, hits
term = QueryS("q", 80)
hits = 0
%>
<!--#include file="includes/header.asp"-->

<div class="page-head">
    <div>
        <h1>Buscar</h1>
        <p class="sub">Canciones, albumes, artistas y playlists publicas.</p>
    </div>
</div>

<%
If Len(term) < 1 Then
    Response.Write EmptyState("search", "Que quieres escuchar?", "Escribe algo en el buscador superior para comenzar.")
Else
    pat = LikePattern(term)
    Response.Write "<div class=""notice notice--info"">Resultados para <b>" & H(term) & "</b></div>"

    ' ---------------- Canciones ----------------
    Set p = New DbParams
    p.Add "@q", adVarChar, 200, pat
    Set rs = DbQuery(SqlSongs("s.SONG_NAME LIKE @q", "s.SONG_NAME"), p)
    Response.Write "<div class=""section""><div class=""section-head""><h2>Canciones</h2></div>"
    If rs Is Nothing Or rs.EOF Then
        Response.Write EmptyState("music", "Sin coincidencias", "Ninguna cancion coincide con la busqueda.")
    Else
        Response.Write "<div class=""tracklist"" data-queue>" & TrackHead()
        num = 0
        Do While Not rs.EOF
            num = num + 1
            hits = hits + 1
            Response.Write SongRow(rs("ID_SONG"), rs("SONG_NAME"), rs("SONG_PATH"), rs("ARTISTS"), _
                                  rs("ALBUM_IMAGE"), rs("PLAYS"), num, _
                                  "<a class=""btn btn--fill btn--sm"" href=""" & APP_VROOT & "/playlist_add.asp?song_id=" & _
                                  rs("ID_SONG") & """ title=""Anadir a una playlist"">+</a>")
            rs.MoveNext
        Loop
        Response.Write "</div>"
    End If
    Response.Write "</div>"

    ' ---------------- Albumes ----------------
    Set p = New DbParams
    p.Add "@q", adVarChar, 200, pat
    Set rs = DbQuery("SELECT ID_ALBUM, TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH FROM TBL_ALBUM " & _
                     "WHERE TITLE_ALBUM LIKE @q ORDER BY TITLE_ALBUM", p)
    Response.Write "<div class=""section""><div class=""section-head""><h2>Albumes</h2></div>"
    If rs Is Nothing Or rs.EOF Then
        Response.Write EmptyState("album", "Sin coincidencias", "Ningun album coincide con la busqueda.")
    Else
        Response.Write "<div class=""grid"">"
        Do While Not rs.EOF
            hits = hits + 1
            Response.Write CardAlbum(rs("ID_ALBUM"), rs("TITLE_ALBUM"), rs("RELEASE_YEAR"), rs("ALBUM_IMAGE_PATH"))
            rs.MoveNext
        Loop
        Response.Write "</div>"
    End If
    Response.Write "</div>"

    ' ---------------- Artistas ----------------
    Set p = New DbParams
    p.Add "@q", adVarChar, 200, pat
    Set rs = DbQuery("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE FROM TBL_ARTIST " & _
                     "WHERE (ARTIST_NAME + ' ' + ISNULL(ARTIST_LASTNAME, '')) LIKE @q " & _
                     "ORDER BY ARTIST_NAME", p)
    Response.Write "<div class=""section""><div class=""section-head""><h2>Artistas</h2></div>"
    If rs Is Nothing Or rs.EOF Then
        Response.Write EmptyState("artist", "Sin coincidencias", "Ningun artista coincide con la busqueda.")
    Else
        Response.Write "<div class=""grid"">"
        Do While Not rs.EOF
            hits = hits + 1
            Response.Write CardArtist(rs("ID_ARTIST"), Trim(rs("ARTIST_NAME") & " " & rs("ARTIST_LASTNAME") & ""), rs("ARTIST_IMAGE"))
            rs.MoveNext
        Loop
        Response.Write "</div>"
    End If
    Response.Write "</div>"

    ' ---------------- Playlists ----------------
    ' Un usuario estandar solo ve las publicas y las propias.
    Set p = New DbParams
    p.Add "@q", adVarChar, 200, pat
    p.Add "@u", adInteger, 0, CurrentUserId()
    Dim sqlPl
    sqlPl = "SELECT p.ID_PLAYLIST, p.TITLE, p.TYPE, p.PHOTO, u.USERNAME " & _
            "FROM TBL_PLAYLIST p INNER JOIN TBL_USER u ON u.ID_USER = p.ID_USER " & _
            "WHERE p.TITLE LIKE @q "
    If Not IsAdmin() Then sqlPl = sqlPl & "AND (p.TYPE = " & PLAYLIST_PUBLIC & " OR p.ID_USER = @u) "
    sqlPl = sqlPl & "ORDER BY p.TITLE"
    Set rs = DbQuery(sqlPl, p)
    Response.Write "<div class=""section""><div class=""section-head""><h2>Playlists</h2></div>"
    If rs Is Nothing Or rs.EOF Then
        Response.Write EmptyState("playlist", "Sin coincidencias", "Ninguna playlist coincide con la busqueda.")
    Else
        Response.Write "<div class=""grid"">"
        Do While Not rs.EOF
            hits = hits + 1
            Response.Write CardPlaylist(rs("ID_PLAYLIST"), rs("TITLE"), rs("USERNAME"), PlaylistTypeName(rs("TYPE")), rs("PHOTO"))
            rs.MoveNext
        Loop
        Response.Write "</div>"
    End If
    Response.Write "</div>"
End If
%>

<!--#include file="includes/footer.asp"-->

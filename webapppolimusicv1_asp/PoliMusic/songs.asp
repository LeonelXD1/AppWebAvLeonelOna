<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  songs.asp - Catalogo completo de canciones
' =====================================================================
RequireLogin()

Dim PageTitle, ActiveNav
PageTitle = "Canciones"
ActiveNav = "songs"

Dim rs, num
%>
<!--#include file="includes/header.asp"-->

<div class="page-head">
    <div>
        <h1>Canciones</h1>
        <p class="sub">Todo el catalogo disponible para reproducir.</p>
    </div>
</div>

<%
Set rs = DbQuery(SqlSongs("", "s.SONG_NAME"), Nothing)
If rs Is Nothing Then
    Response.Write "<div class=""notice notice--danger"">No se pudo cargar el catalogo: " & H(LastDbError) & "</div>"
ElseIf rs.EOF Then
    Response.Write EmptyState("music", "Sin canciones", "El catalogo todavia esta vacio.")
Else
    Response.Write "<div class=""tracklist"" data-queue>" & TrackHead()
    num = 0
    Do While Not rs.EOF
        num = num + 1
        Response.Write SongRow(rs("ID_SONG"), rs("SONG_NAME"), rs("SONG_PATH"), rs("ARTISTS"), _
                              rs("ALBUM_IMAGE"), rs("PLAYS"), num, _
                              "<a class=""btn btn--fill btn--sm"" href=""" & APP_VROOT & "/playlist_add.asp?song_id=" & _
                              rs("ID_SONG") & """ title=""Anadir a una playlist"">+</a>")
        rs.MoveNext
    Loop
    Response.Write "</div>"
End If
%>

<!--#include file="includes/footer.asp"-->

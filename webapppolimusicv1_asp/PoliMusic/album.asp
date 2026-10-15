<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  album.asp - Detalle de album con su tracklist
' =====================================================================
RequireLogin()

Dim PageTitle, ActiveNav
PageTitle = "Album"
ActiveNav = "albums"

Dim p, rs, albumId, num, firstUrl, firstCover
albumId = QueryInt("id", 0)
If albumId <= 0 Then Response.Redirect APP_VROOT & "/albums.asp"

Set p = New DbParams
p.Add "@id", adInteger, 0, albumId
Set rs = DbQuery("SELECT ID_ALBUM, TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH FROM TBL_ALBUM WHERE ID_ALBUM = @id", p)
If rs Is Nothing Or rs.EOF Then
    Response.Redirect APP_VROOT & "/albums.asp?err=noencontrado"
End If

Dim aTitle, aYear, aImage, aId
aId    = rs("ID_ALBUM")
aTitle = rs("TITLE_ALBUM")
aYear  = rs("RELEASE_YEAR")
aImage = rs("ALBUM_IMAGE_PATH")
rs.Close

PageTitle = aTitle

Dim rsSongs
Set p = New DbParams
p.Add "@id", adInteger, 0, albumId
Set rsSongs = DbQuery(SQL_ALBUM_SONGS, p)

Dim songCount
songCount = 0
If Not (rsSongs Is Nothing) Then
    If Not rsSongs.EOF Then
        firstUrl   = SongUrl(rsSongs("SONG_PATH"))
        firstCover = AlbumImage(aImage)
        Do While Not rsSongs.EOF
            songCount = songCount + 1
            rsSongs.MoveNext
        Loop
        rsSongs.MoveFirst
    End If
End If
%>
<!--#include file="includes/header.asp"-->

<div class="hero">
    <img class="hero__art" src="<%=HAttr(AlbumImage(aImage))%>" alt="Caratula del album">
    <div class="hero__meta">
        <div class="hero__eyebrow">Album</div>
        <h1><%=H(aTitle)%></h1>
        <div class="hero__facts">
            <span><%=H(aYear)%></span>
            <span class="dot">&bull;</span>
            <span><%=songCount%> canciones</span>
        </div>
        <div class="hero__actions">
            <% If songCount > 0 And firstUrl <> "" Then %>
                <button type="button" class="btn btn--primary" data-play
                        data-id="<%=HAttr(albumId)%>" data-title="<%=HAttr(aTitle)%>"
                        data-artist="Album completo" data-url="<%=HAttr(firstUrl)%>"
                        data-cover="<%=HAttr(firstCover)%>">&#9654; Reproducir</button>
            <% End If %>
            <a class="btn btn--ghost" href="<%=APP_VROOT%>/albums.asp">Volver a albumes</a>
        </div>
    </div>
</div>

<%
If rsSongs Is Nothing Then
    Response.Write "<div class=""notice notice--danger"">No se pudo cargar el tracklist: " & H(LastDbError) & "</div>"
ElseIf rsSongs.EOF Then
    Response.Write EmptyState("music", "Album sin canciones", "Este album todavia no tiene pistas asociadas.")
Else
    Response.Write "<div class=""tracklist"" data-queue>" & TrackHead()
    num = 0
    Do While Not rsSongs.EOF
        num = num + 1
        Response.Write SongRow(rsSongs("ID_SONG"), rsSongs("SONG_NAME"), rsSongs("SONG_PATH"), _
                              rsSongs("ARTISTS"), rsSongs("ALBUM_IMAGE"), rsSongs("PLAYS"), num, _
                              "<a class=""btn btn--fill btn--sm"" href=""" & APP_VROOT & "/playlist_add.asp?song_id=" & _
                              rsSongs("ID_SONG") & """ title=""Anadir a una playlist"">+</a>")
        rsSongs.MoveNext
    Loop
    Response.Write "</div>"
End If
%>

<!--#include file="includes/footer.asp"-->

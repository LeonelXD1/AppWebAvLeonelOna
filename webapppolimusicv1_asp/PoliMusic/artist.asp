<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  artist.asp - Detalle de artista con sus canciones
' =====================================================================
RequireLogin()

Dim PageTitle, ActiveNav
PageTitle = "Artista"
ActiveNav = "artists"

Dim p, rs, artistId, num, firstUrl, firstCover
artistId = QueryInt("id", 0)
If artistId <= 0 Then Response.Redirect APP_VROOT & "/artists.asp"

Set p = New DbParams
p.Add "@id", adInteger, 0, artistId
Set rs = DbQuery("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE FROM TBL_ARTIST WHERE ID_ARTIST = @id", p)
If rs Is Nothing Or rs.EOF Then
    Response.Redirect APP_VROOT & "/artists.asp?err=noencontrado"
End If

Dim aName, aImage, aId
aId    = rs("ID_ARTIST")
aName  = Trim(rs("ARTIST_NAME") & " " & rs("ARTIST_LASTNAME") & "")
aImage = rs("ARTIST_IMAGE")
rs.Close

PageTitle = aName

Dim rsSongs, songCount
Set p = New DbParams
p.Add "@id", adInteger, 0, artistId
Set rsSongs = DbQuery(SQL_ARTIST_SONGS, p)

songCount = 0
If Not (rsSongs Is Nothing) Then
    If Not rsSongs.EOF Then
        firstUrl   = SongUrl(rsSongs("SONG_PATH"))
        firstCover = AlbumImage(rsSongs("ALBUM_IMAGE"))
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
    <img class="hero__art hero__art--round" src="<%=HAttr(ArtistImage(aImage))%>" alt="Imagen del artista">
    <div class="hero__meta">
        <div class="hero__eyebrow">Artista</div>
        <h1><%=H(aName)%></h1>
        <div class="hero__facts">
            <span><%=songCount%> canciones en el catalogo</span>
        </div>
        <div class="hero__actions">
            <% If songCount > 0 And firstUrl <> "" Then %>
                <button type="button" class="btn btn--primary" data-play
                        data-id="<%=HAttr(artistId)%>" data-title="<%=HAttr(aName)%>"
                        data-artist="Discografia" data-url="<%=HAttr(firstUrl)%>"
                        data-cover="<%=HAttr(firstCover)%>">&#9654; Reproducir</button>
            <% End If %>
            <a class="btn btn--ghost" href="<%=APP_VROOT%>/artists.asp">Volver a artistas</a>
        </div>
    </div>
</div>

<%
If rsSongs Is Nothing Then
    Response.Write "<div class=""notice notice--danger"">No se pudieron cargar las canciones: " & H(LastDbError) & "</div>"
ElseIf rsSongs.EOF Then
    Response.Write EmptyState("music", "Sin canciones", "Este artista no tiene canciones asociadas.")
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

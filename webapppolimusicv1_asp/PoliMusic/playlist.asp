<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  playlist.asp - Detalle de playlist + acciones (anadir/quitar/eliminar)
'
'  Reglas de acceso:
'   * Playlist privada  -> solo su propietario y el administrador.
'   * Playlist publica  -> visible para todos, editable solo por su
'                          propietario y el administrador.
' =====================================================================
RequireLogin()

Dim PageTitle, ActiveNav
PageTitle = "Playlist"
ActiveNav = "playlists"

Dim plId, action, songId, p, rs
Dim plTitle, plType, plPhoto, plOwner, plOwnerName, plDate, canEdit

' --- Identificacion de la playlist (POST o GET) ---
If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    plId = FormInt("playlist_id", 0)
Else
    plId = QueryInt("id", 0)
End If
If plId <= 0 Then Response.Redirect APP_VROOT & "/playlists.asp"

' --- Carga y control de acceso ---
Set p = New DbParams
p.Add "@id", adInteger, 0, plId
Set rs = DbQuery("SELECT p.ID_PLAYLIST, p.ID_USER, p.TITLE, p.CREATION_DATE, p.TYPE, p.PHOTO, u.USERNAME " & _
                 "FROM TBL_PLAYLIST p INNER JOIN TBL_USER u ON u.ID_USER = p.ID_USER " & _
                 "WHERE p.ID_PLAYLIST = @id", p)
If rs Is Nothing Or rs.EOF Then
    Response.Redirect APP_VROOT & "/playlists.asp?err=noencontrado"
End If

plTitle     = CStr(rs("TITLE") & "")
plType      = CInt(rs("TYPE"))
plPhoto     = CStr(rs("PHOTO") & "")
plOwner     = CLng(rs("ID_USER"))
plOwnerName = CStr(rs("USERNAME") & "")
plDate      = rs("CREATION_DATE")
rs.Close

canEdit = CanManagePlaylist(plOwner)

' Una playlist privada ajena no es visible.
If (plType = PLAYLIST_PRIVATE) And (Not canEdit) Then
    Response.Redirect APP_VROOT & "/playlists.asp?err=denegado"
End If

' --- Acciones POST ---
If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    action = FormS("action", 20)
    songId = FormInt("song_id", 0)

    If action = "add" And canEdit Then
        If songId > 0 Then
            Set p = New DbParams
            p.Add "@pl", adInteger, 0, plId
            p.Add "@sg", adInteger, 0, songId
            If DbExec("INSERT INTO TBL_PLAYLIST_SONG (ID_PLAYLIST, ID_SONG) " & _
                      "SELECT @pl, @sg WHERE NOT EXISTS (SELECT 1 FROM TBL_PLAYLIST_SONG " & _
                      "WHERE ID_PLAYLIST = @pl AND ID_SONG = @sg)", p) Then
                FlashSet "ok", "Cancion anadida a la playlist."
            Else
                FlashSet "error", "No se pudo anadir la cancion: " & LastDbError
            End If
        End If

    ElseIf action = "remove" And canEdit Then
        If songId > 0 Then
            Set p = New DbParams
            p.Add "@pl", adInteger, 0, plId
            p.Add "@sg", adInteger, 0, songId
            If DbExec("DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = @pl AND ID_SONG = @sg", p) Then
                FlashSet "ok", "Cancion quitada de la playlist."
            Else
                FlashSet "error", "No se pudo quitar la cancion: " & LastDbError
            End If
        End If

    ElseIf action = "delete" And canEdit Then
        Set p = New DbParams
        p.Add "@pl", adInteger, 0, plId
        DbExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = @pl", p
        If DbExec("DELETE FROM TBL_PLAYLIST WHERE ID_PLAYLIST = @pl", p) Then
            FlashSet "ok", "Playlist eliminada correctamente."
        Else
            FlashSet "error", "No se pudo eliminar la playlist: " & LastDbError
        End If
        Response.Redirect APP_VROOT & "/playlists.asp"
    End If

    Response.Redirect APP_VROOT & "/playlist.asp?id=" & plId
End If

PageTitle = plTitle

Dim rsSongs, num, songCount, firstUrl, firstCover, rowAction
Set p = New DbParams
p.Add "@id", adInteger, 0, plId
Set rsSongs = DbQuery(SQL_PLAYLIST_SONGS, p)

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

' Canciones candidatas para anadir (las que aun no estan)
Dim rsAvailable
Set rsAvailable = Nothing
If canEdit Then
    Set p = New DbParams
    p.Add "@id", adInteger, 0, plId
    Set rsAvailable = DbQuery("SELECT s.ID_SONG, s.SONG_NAME FROM TBL_SONG s " & _
        "WHERE NOT EXISTS (SELECT 1 FROM TBL_PLAYLIST_SONG ps " & _
        "                  WHERE ps.ID_PLAYLIST = @id AND ps.ID_SONG = s.ID_SONG) " & _
        "ORDER BY s.SONG_NAME", p)
End If
%>
<!--#include file="includes/header.asp"-->

<div class="hero">
    <img class="hero__art" src="<%=HAttr(PlaylistPhoto(plPhoto))%>" alt="Portada de la playlist">
    <div class="hero__meta">
        <div class="hero__eyebrow">Playlist <%=H(PlaylistTypeName(plType))%></div>
        <h1><%=H(plTitle)%></h1>
        <div class="hero__facts">
            <span>Creada por <b><%=H(plOwnerName)%></b></span>
            <span class="dot">&bull;</span>
            <span><%=FmtDate(plDate)%></span>
            <span class="dot">&bull;</span>
            <span><%=songCount%> canciones</span>
        </div>
        <div class="hero__actions">
            <% If songCount > 0 And firstUrl <> "" Then %>
                <button type="button" class="btn btn--primary" data-play
                        data-id="<%=HAttr(plId)%>" data-title="<%=HAttr(plTitle)%>"
                        data-artist="<%=HAttr(plOwnerName)%>" data-url="<%=HAttr(firstUrl)%>"
                        data-cover="<%=HAttr(firstCover)%>">&#9654; Reproducir</button>
            <% End If %>
            <% If canEdit Then %>
                <a class="btn btn--ghost" href="<%=APP_VROOT%>/playlist_form.asp?id=<%=plId%>">Editar datos</a>
                <%
                Response.Write MiniForm(APP_VROOT & "/playlist.asp", _
                    Hidden("action", "delete") & Hidden("playlist_id", plId), _
                    "Eliminar playlist", "btn btn--danger", _
                    "Eliminar la playlist y todas sus canciones?", "trash")
                %>
            <% End If %>
            <a class="btn btn--ghost" href="<%=APP_VROOT%>/playlists.asp">Volver</a>
        </div>
    </div>
</div>

<%
If rsSongs Is Nothing Then
    Response.Write "<div class=""notice notice--danger"">No se pudieron cargar las canciones: " & H(LastDbError) & "</div>"
ElseIf rsSongs.EOF Then
    Response.Write EmptyState("music", "Playlist vacia", "Todavia no hay canciones en esta playlist.")
Else
    Response.Write "<div class=""tracklist"" data-queue>" & TrackHead()
    num = 0
    Do While Not rsSongs.EOF
        num = num + 1
        rowAction = ""
        If canEdit Then
            rowAction = MiniForm(APP_VROOT & "/playlist.asp", _
                                 Hidden("action", "remove") & Hidden("playlist_id", plId) & _
                                 Hidden("song_id", rsSongs("ID_SONG")), _
                                 "Quitar", "btn btn--danger btn--sm", "Quitar esta cancion de la playlist?", "trash")
        End If
        Response.Write SongRow(rsSongs("ID_SONG"), rsSongs("SONG_NAME"), rsSongs("SONG_PATH"), _
                              rsSongs("ARTISTS"), rsSongs("ALBUM_IMAGE"), rsSongs("PLAYS"), num, rowAction)
        rsSongs.MoveNext
    Loop
    Response.Write "</div>"
End If
%>

<% If canEdit Then %>
<div class="panel" style="margin-top:26px">
    <h2>Anadir canciones</h2>
    <%
    If rsAvailable Is Nothing Or rsAvailable.EOF Then
        Response.Write "<p class=""sub"">No quedan canciones por anadir: ya estan todas en la playlist.</p>"
    Else
    %>
    <form method="post" action="<%=APP_VROOT%>/playlist.asp">
        <%=CsrfField()%>
        <%=Hidden("action", "add")%>
        <%=Hidden("playlist_id", plId)%>
        <div class="form-grid">
            <div class="field" style="margin-bottom:0">
                <label for="song_id">Cancion del catalogo</label>
                <select id="song_id" name="song_id" required>
                    <%
                    Do While Not rsAvailable.EOF
                        Response.Write "<option value=""" & HAttr(rsAvailable("ID_SONG")) & """>" & _
                                       H(rsAvailable("SONG_NAME")) & "</option>"
                        rsAvailable.MoveNext
                    Loop
                    %>
                </select>
            </div>
            <div class="field" style="margin-bottom:0;display:flex;align-items:flex-end">
                <button type="submit" class="btn btn--primary">+ Anadir a la playlist</button>
            </div>
        </div>
    </form>
    <% End If %>
</div>
<% End If %>

<!--#include file="includes/footer.asp"-->

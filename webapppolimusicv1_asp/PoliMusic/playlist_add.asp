<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  playlist_add.asp - Anadir una cancion concreta a una playlist
'  Solo permite operar sobre playlists del propio usuario (o cualquiera
'  si el perfil es administrador).
' =====================================================================
RequireLogin()

Dim PageTitle, ActiveNav
PageTitle = "Anadir a playlist"
ActiveNav = "playlists"

Dim songId, p, rs, errMsg
songId = QueryInt("song_id", 0)
errMsg = ""

' --- Acciones POST ---
If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    Dim act, targetPl, newTitle, newType, newId
    act      = FormS("action", 20)
    targetPl = FormInt("playlist_id", 0)
    songId   = FormInt("song_id", 0)
    newTitle = FormS("title", LEN_TITLE)
    newType  = FormInt("type", PLAYLIST_PUBLIC)
    If newType <> PLAYLIST_PRIVATE Then newType = PLAYLIST_PUBLIC

    If act = "create" Then
        ' Crear playlist y anadir la cancion en el mismo paso.
        If Len(newTitle) < 1 Then
            errMsg = "Indica un titulo para la nueva playlist."
        Else
            Set p = New DbParams
            p.Add "@u", adInteger, 0, CurrentUserId()
            p.Add "@t", adVarChar, LEN_TITLE, newTitle
            p.Add "@y", adInteger, 0, newType
            p.Add "@ph", adVarChar, LEN_PATH, "~/playlistImages/default.jpg"
            newId = DbInsertReturnId("INSERT INTO TBL_PLAYLIST (ID_USER, TITLE, CREATION_DATE, TYPE, PHOTO) " & _
                                     "VALUES (@u, @t, GETDATE(), @y, @ph)", p)
            If newId > 0 Then
                Set p = New DbParams
                p.Add "@pl", adInteger, 0, newId
                p.Add "@sg", adInteger, 0, songId
                DbExec "INSERT INTO TBL_PLAYLIST_SONG (ID_PLAYLIST, ID_SONG) " & _
                       "SELECT @pl, @sg WHERE NOT EXISTS (SELECT 1 FROM TBL_PLAYLIST_SONG " & _
                       "WHERE ID_PLAYLIST = @pl AND ID_SONG = @sg)", p
                FlashSet "ok", "Playlist creada con la cancion anadida."
                Response.Redirect APP_VROOT & "/playlist.asp?id=" & newId
            Else
                errMsg = "No se pudo crear la playlist: " & LastDbError
            End If
        End If

    ElseIf act = "add" Then
        ' Anadir a una playlist existente, verificando la propiedad.
        Set p = New DbParams
        p.Add "@id", adInteger, 0, targetPl
        Set rs = DbQuery("SELECT ID_USER FROM TBL_PLAYLIST WHERE ID_PLAYLIST = @id", p)
        If rs Is Nothing Or rs.EOF Then
            errMsg = "La playlist seleccionada no existe."
        ElseIf Not CanManagePlaylist(rs("ID_USER")) Then
            errMsg = "Solo puedes modificar tus propias playlists."
            rs.Close
        Else
            rs.Close
            Set p = New DbParams
            p.Add "@pl", adInteger, 0, targetPl
            p.Add "@sg", adInteger, 0, songId
            If DbExec("INSERT INTO TBL_PLAYLIST_SONG (ID_PLAYLIST, ID_SONG) " & _
                      "SELECT @pl, @sg WHERE NOT EXISTS (SELECT 1 FROM TBL_PLAYLIST_SONG " & _
                      "WHERE ID_PLAYLIST = @pl AND ID_SONG = @sg)", p) Then
                FlashSet "ok", "Cancion anadida a la playlist."
                Response.Redirect APP_VROOT & "/playlist.asp?id=" & targetPl
            Else
                errMsg = "No se pudo anadir la cancion: " & LastDbError
            End If
        End If
    End If
End If

' --- Datos de la cancion ---
Dim sName, sArtists, sImage, sPath
Set p = New DbParams
p.Add "@id", adInteger, 0, songId
Set rs = DbQuery("SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, " & _
                 "ISNULL((SELECT TOP 1 al.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST t " & _
                 "        INNER JOIN TBL_ALBUM al ON al.ID_ALBUM = t.ID_ALBUM " & _
                 "        WHERE t.ID_SONG = s.ID_SONG), '') AS ALBUM_IMAGE, " & _
                 "ISNULL((SELECT TOP 1 STUFF((SELECT ', ' + a.ARTIST_NAME + ' ' + ISNULL(a.ARTIST_LASTNAME, '') " & _
                 "        FROM TBL_PLAYER pl INNER JOIN TBL_ARTIST a ON a.ID_ARTIST = pl.ID_ARTIST " & _
                 "        WHERE pl.ID_SONG = s.ID_SONG FOR XML PATH('')), 1, 2, '')), 'Artista desconocido') AS ARTISTS " & _
                 "FROM TBL_SONG s WHERE s.ID_SONG = @id", p)
If rs Is Nothing Or rs.EOF Then
    Response.Redirect APP_VROOT & "/songs.asp?err=noencontrado"
End If
sName    = CStr(rs("SONG_NAME") & "")
sArtists = CStr(rs("ARTISTS") & "")
sImage   = CStr(rs("ALBUM_IMAGE") & "")
sPath    = CStr(rs("SONG_PATH") & "")
rs.Close
%>
<!--#include file="includes/header.asp"-->

<div class="page-head">
    <div>
        <h1>Anadir a una playlist</h1>
        <p class="sub">Elige el destino de la cancion seleccionada.</p>
    </div>
    <div>
        <a class="btn btn--ghost" href="<%=APP_VROOT%>/songs.asp">Volver al catalogo</a>
    </div>
</div>

<% If errMsg <> "" Then %>
    <div class="notice notice--danger"><%=H(errMsg)%></div>
<% End If %>

<div class="panel" style="display:flex;gap:16px;align-items:center;flex-wrap:wrap">
    <img src="<%=HAttr(AlbumImage(sImage))%>" alt="" style="width:64px;height:64px;border-radius:9px;object-fit:cover">
    <div>
        <div style="font-weight:700;font-size:1.05rem"><%=H(sName)%></div>
        <div class="sub" style="color:var(--muted);font-size:13.5px"><%=H(sArtists)%></div>
    </div>
</div>

<div class="section">
    <div class="section-head"><h2>Mis playlists</h2></div>
    <%
    Set p = New DbParams
    p.Add "@u", adInteger, 0, CurrentUserId()
    p.Add "@s", adInteger, 0, songId
    Set rs = DbQuery("SELECT p.ID_PLAYLIST, p.TITLE, p.TYPE, p.PHOTO, " & _
                     "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = p.ID_PLAYLIST) AS N, " & _
                     "CASE WHEN EXISTS (SELECT 1 FROM TBL_PLAYLIST_SONG ps2 " & _
                     "                  WHERE ps2.ID_PLAYLIST = p.ID_PLAYLIST AND ps2.ID_SONG = @s) " & _
                     "     THEN 1 ELSE 0 END AS YA " & _
                     "FROM TBL_PLAYLIST p WHERE p.ID_USER = @u ORDER BY p.TITLE", p)
    If rs Is Nothing Then
        Response.Write "<div class=""notice notice--danger"">No se pudieron cargar tus playlists: " & H(LastDbError) & "</div>"
    ElseIf rs.EOF Then
        Response.Write EmptyState("playlist", "Sin playlists", "Crea una playlist nueva aqui abajo.")
    Else
        Response.Write "<div class=""table-wrap""><table class=""data""><thead><tr>" & _
                       "<th></th><th>Playlist</th><th>Visibilidad</th><th>Canciones</th><th></th>" & _
                       "</tr></thead><tbody>"
        Do While Not rs.EOF
            Response.Write "<tr>"
            Response.Write "<td><img class=""thumb"" src=""" & HAttr(PlaylistPhoto(rs("PHOTO"))) & """ alt=""""></td>"
            Response.Write "<td><a href=""" & APP_VROOT & "/playlist.asp?id=" & rs("ID_PLAYLIST") & """>" & _
                           H(rs("TITLE")) & "</a></td>"
            Response.Write "<td><span class=""badge "
            If CInt(rs("TYPE")) = PLAYLIST_PRIVATE Then
                Response.Write "badge-priv"">Privada"
            Else
                Response.Write "badge-pub"">Publica"
            End If
            Response.Write "</span></td>"
            Response.Write "<td>" & H(rs("N")) & "</td>"
            Response.Write "<td class=""actions"">"
            If CInt(rs("YA")) = 1 Then
                Response.Write "<span class=""tag"">ya incluida</span>"
            Else
                Response.Write MiniForm(APP_VROOT & "/playlist_add.asp", _
                    Hidden("action", "add") & Hidden("playlist_id", rs("ID_PLAYLIST")) & Hidden("song_id", songId), _
                    "Anadir", "btn btn--primary btn--sm", "", "plus")
            End If
            Response.Write "</td></tr>"
            rs.MoveNext
        Loop
        Response.Write "</tbody></table></div>"
    End If
    %>
</div>

<div class="panel" style="max-width:640px">
    <h2>O crea una playlist nueva</h2>
    <form method="post" action="<%=APP_VROOT%>/playlist_add.asp">
        <%=CsrfField()%>
        <%=Hidden("action", "create")%>
        <%=Hidden("song_id", songId)%>
        <div class="form-grid">
            <div class="field">
                <label for="title">Titulo</label>
                <input type="text" id="title" name="title" maxlength="<%=LEN_TITLE%>" required placeholder="Mi nueva playlist">
            </div>
            <div class="field">
                <label for="type">Visibilidad</label>
                <select id="type" name="type">
                    <option value="<%=PLAYLIST_PUBLIC%>">Publica</option>
                    <option value="<%=PLAYLIST_PRIVATE%>">Privada</option>
                </select>
            </div>
        </div>
        <div class="form-actions">
            <button type="submit" class="btn btn--primary">Crear y anadir</button>
        </div>
    </form>
</div>

<!--#include file="includes/footer.asp"-->

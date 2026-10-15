<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include virtual="/PoliMusic/includes/app.asp"-->
<%
' =====================================================================
'  admin/playlist_edit.asp - Alta y edicion de playlists (administrador)
'  Permite ademas reasignar el propietario y gestionar las canciones.
' =====================================================================
RequireAdmin()

Dim PageTitle, ActiveNav, AdminTab
ActiveNav = "admin"
AdminTab = "playlists"

Dim plId, isEdit, errMsg, p, rs
Dim fTitle, fType, fPhoto, fOwner

plId   = QueryInt("id", 0)
isEdit = (plId > 0)
errMsg = ""
fTitle = ""
fType  = PLAYLIST_PUBLIC
fPhoto = "~/playlistImages/default.jpg"
fOwner = CurrentUserId()

If isEdit Then
    Set p = New DbParams
    p.Add "@id", adInteger, 0, plId
    Set rs = DbQuery("SELECT ID_PLAYLIST, ID_USER, TITLE, TYPE, PHOTO FROM TBL_PLAYLIST WHERE ID_PLAYLIST = @id", p)
    If rs Is Nothing Or rs.EOF Then
        Response.Redirect APP_VROOT & "/admin/playlists.asp?err=noencontrado"
    End If
    fOwner = ToInt(rs("ID_USER"), 0)
    fTitle = CStr(rs("TITLE") & "")
    fType  = CInt(rs("TYPE"))
    fPhoto = CStr(rs("PHOTO") & "")
    rs.Close
End If

If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    fTitle = FormS("title", LEN_TITLE)
    fType  = FormInt("type", PLAYLIST_PUBLIC)
    fPhoto = FormS("photo", LEN_PATH)
    fOwner = FormInt("owner_id", CurrentUserId())
    If fType <> PLAYLIST_PRIVATE Then fType = PLAYLIST_PUBLIC

    ' Lista blanca de portadas.
    Dim allowed, fso, fld, f, okPhoto
    allowed = "|~/playlistImages/default.jpg|"
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    If fso.FolderExists(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/playlistImages")) Then
        Set fld = fso.GetFolder(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/playlistImages"))
        For Each f In fld.Files
            allowed = allowed & "~/playlistImages/" & f.Name & "|"
        Next
    End If
    okPhoto = (InStr(LCase(allowed), LCase("|" & fPhoto & "|")) > 0)
    If Not okPhoto Then fPhoto = "~/playlistImages/default.jpg"

    ' El propietario debe existir.
    Set p = New DbParams
    p.Add "@u", adInteger, 0, fOwner
    Dim ownerOk
    ownerOk = (ToInt(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE ID_USER = @u", p), 0) > 0)

    If Len(fTitle) < 1 Then
        errMsg = "El titulo de la playlist es obligatorio."
    ElseIf Not ownerOk Then
        errMsg = "El propietario seleccionado no existe."
    Else
        Dim newId
        If isEdit Then
            Set p = New DbParams
            p.Add "@t",  adVarChar, LEN_TITLE, fTitle
            p.Add "@y",  adInteger, 0,         fType
            p.Add "@ph", adVarChar, LEN_PATH,  fPhoto
            p.Add "@o",  adInteger, 0,         fOwner
            p.Add "@id", adInteger, 0,         plId
            If DbExec("UPDATE TBL_PLAYLIST SET TITLE = @t, TYPE = @y, PHOTO = @ph, ID_USER = @o WHERE ID_PLAYLIST = @id", p) Then
                newId = plId
            Else
                errMsg = "No se pudo actualizar la playlist: " & LastDbError
            End If
        Else
            Set p = New DbParams
            p.Add "@o",  adInteger, 0,         fOwner
            p.Add "@t",  adVarChar, LEN_TITLE, fTitle
            p.Add "@y",  adInteger, 0,         fType
            p.Add "@ph", adVarChar, LEN_PATH,  fPhoto
            newId = DbInsertReturnId("INSERT INTO TBL_PLAYLIST (ID_USER, TITLE, CREATION_DATE, TYPE, PHOTO) " & _
                                     "VALUES (@o, @t, GETDATE(), @y, @ph)", p)
            If newId <= 0 Then errMsg = "No se pudo crear la playlist: " & LastDbError
        End If

        If errMsg = "" And newId > 0 Then
            FlashSet "ok", IIf(isEdit, "Playlist actualizada correctamente.", "Playlist creada correctamente.")
            Response.Redirect APP_VROOT & "/admin/playlist_edit.asp?id=" & newId
        End If
    End If
End If

PageTitle = IIf(isEdit, "Editar playlist", "Nueva playlist")

Dim rsUsers, rsSongs, rsAvail
Set rsUsers = DbQuery("SELECT ID_USER, USERNAME, USER_TYPE FROM TBL_USER ORDER BY USERNAME", Nothing)

Set rsSongs = Nothing
Set rsAvail = Nothing
If isEdit Then
    Set p = New DbParams
    p.Add "@id", adInteger, 0, plId
    Set rsSongs = DbQuery(SQL_PLAYLIST_SONGS, p)
    Set p = New DbParams
    p.Add "@id", adInteger, 0, plId
    Set rsAvail = DbQuery("SELECT s.ID_SONG, s.SONG_NAME FROM TBL_SONG s " & _
        "WHERE NOT EXISTS (SELECT 1 FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = @id AND ps.ID_SONG = s.ID_SONG) " & _
        "ORDER BY s.SONG_NAME", p)
End If
%>
<!--#include virtual="/PoliMusic/includes/header.asp"-->

<div class="page-head">
    <div>
        <h1><%=H(PageTitle)%></h1>
        <p class="sub">Datos de la playlist y su contenido.</p>
    </div>
    <div>
        <a class="btn btn--ghost" href="<%=APP_VROOT%>/admin/playlists.asp">Volver</a>
    </div>
</div>

<!--#include file="nav.asp"-->

<div class="panel" style="max-width:820px">
    <% If errMsg <> "" Then %>
        <div class="notice notice--danger"><%=H(errMsg)%></div>
    <% End If %>

    <form method="post" action="<%=APP_VROOT%>/admin/playlist_edit.asp<% If isEdit Then %>?id=<%=plId%><% End If %>">
        <%=CsrfField()%>

        <div class="form-grid">
            <div class="field">
                <label for="title">Titulo</label>
                <input type="text" id="title" name="title" maxlength="<%=LEN_TITLE%>" required value="<%=HAttr(fTitle)%>">
            </div>
            <div class="field">
                <label for="owner_id">Propietario</label>
                <select id="owner_id" name="owner_id" required>
                    <%
                    If Not (rsUsers Is Nothing) Then
                        Do While Not rsUsers.EOF
                            Response.Write "<option value=""" & rsUsers("ID_USER") & """"
                            If ToInt(rsUsers("ID_USER"), 0) = fOwner Then Response.Write " selected"
                            Response.Write ">" & H(rsUsers("USERNAME")) & _
                                           IIf(CInt(rsUsers("USER_TYPE")) = USER_TYPE_ADMIN, " (admin)", "") & "</option>"
                            rsUsers.MoveNext
                        Loop
                    End If
                    %>
                </select>
            </div>
        </div>

        <div class="form-grid">
            <div class="field">
                <label for="type">Visibilidad</label>
                <select id="type" name="type">
                    <option value="<%=PLAYLIST_PUBLIC%>" <% If fType = PLAYLIST_PUBLIC Then Response.Write "selected" %>>Publica</option>
                    <option value="<%=PLAYLIST_PRIVATE%>" <% If fType = PLAYLIST_PRIVATE Then Response.Write "selected" %>>Privada</option>
                </select>
            </div>
            <div class="field">
                <label for="photo">Portada</label>
                <select id="photo" name="photo">
                    <%
                    Dim fso2, fld2, f2, logical
                    Set fso2 = Server.CreateObject("Scripting.FileSystemObject")
                    If fso2.FolderExists(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/playlistImages")) Then
                        Set fld2 = fso2.GetFolder(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/playlistImages"))
                        For Each f2 In fld2.Files
                            logical = "~/playlistImages/" & f2.Name
                            Response.Write "<option value=""" & HAttr(logical) & """"
                            If LCase(logical) = LCase(fPhoto) Then Response.Write " selected"
                            Response.Write ">" & H(f2.Name) & "</option>"
                        Next
                    End If
                    %>
                </select>
            </div>
        </div>

        <div class="form-actions">
            <button type="submit" class="btn btn--primary"><% If isEdit Then %>Guardar cambios<% Else %>Crear playlist<% End If %></button>
            <a class="btn btn--ghost" href="<%=APP_VROOT%>/admin/playlists.asp">Cancelar</a>
        </div>
    </form>
</div>

<% If isEdit Then %>
<div class="panel" style="max-width:820px">
    <h2>Canciones de la playlist</h2>
    <%
    If rsSongs Is Nothing Or rsSongs.EOF Then
        Response.Write "<p class=""sub"">La playlist esta vacia.</p>"
    Else
        Response.Write "<div class=""table-wrap""><table class=""data""><thead><tr>" & _
                       "<th>#</th><th>Cancion</th><th>Artistas</th><th>Album</th><th></th>" & _
                       "</tr></thead><tbody>"
        Dim tn
        tn = 0
        Do While Not rsSongs.EOF
            tn = tn + 1
            Response.Write "<tr><td>" & tn & "</td>" & _
                           "<td>" & H(rsSongs("SONG_NAME")) & "</td>" & _
                           "<td>" & H(rsSongs("ARTISTS")) & "</td>" & _
                           "<td>" & H(rsSongs("ALBUM_TITLE") & "") & "</td>" & _
                           "<td class=""actions"">" & _
                           MiniForm(APP_VROOT & "/admin/playlist_track.asp", _
                              Hidden("action", "remove") & Hidden("playlist_id", plId) & Hidden("song_id", rsSongs("ID_SONG")), _
                              "Quitar", "btn btn--danger btn--sm", "Quitar la cancion de la playlist?", "trash") & _
                           "</td></tr>"
            rsSongs.MoveNext
        Loop
        Response.Write "</tbody></table></div>"
    End If
    %>

    <h3 style="margin-top:20px">Anadir cancion</h3>
    <%
    If rsAvail Is Nothing Or rsAvail.EOF Then
        Response.Write "<p class=""sub"">Todas las canciones del catalogo ya estan en esta playlist.</p>"
    Else
    %>
    <form method="post" action="<%=APP_VROOT%>/admin/playlist_track.asp">
        <%=CsrfField()%>
        <%=Hidden("action", "add")%>
        <%=Hidden("playlist_id", plId)%>
        <div class="form-grid">
            <div class="field" style="margin-bottom:0">
                <label for="song_id">Cancion</label>
                <select id="song_id" name="song_id" required>
                    <%
                    Do While Not rsAvail.EOF
                        Response.Write "<option value=""" & HAttr(rsAvail("ID_SONG")) & """>" & H(rsAvail("SONG_NAME")) & "</option>"
                        rsAvail.MoveNext
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

<!--#include virtual="/PoliMusic/includes/footer.asp"-->

<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  playlist_form.asp - Crear o editar una playlist
'   * Crear: cualquier usuario autenticado (la playlist es suya).
'   * Editar: solo el propietario o un administrador.
' =====================================================================
RequireLogin()

Dim PageTitle, ActiveNav
ActiveNav = "playlists"

Dim plId, isEdit, errMsg, p, rs
Dim fTitle, fType, fPhoto
Dim ownerId, canEdit

plId   = QueryInt("id", 0)
isEdit = (plId > 0)
errMsg = ""
ownerId = 0
canEdit = True
fTitle = ""
fType  = PLAYLIST_PUBLIC
fPhoto = "~/playlistImages/default.jpg"

' --- Edicion: cargar y validar permisos ---
If isEdit Then
    Set p = New DbParams
    p.Add "@id", adInteger, 0, plId
    Set rs = DbQuery("SELECT ID_PLAYLIST, ID_USER, TITLE, TYPE, PHOTO FROM TBL_PLAYLIST WHERE ID_PLAYLIST = @id", p)
    If rs Is Nothing Or rs.EOF Then
        Response.Redirect APP_VROOT & "/playlists.asp?err=noencontrado"
    End If
    ownerId = CLng(rs("ID_USER"))
    fTitle  = CStr(rs("TITLE") & "")
    fType   = CInt(rs("TYPE"))
    fPhoto  = CStr(rs("PHOTO") & "")
    rs.Close

    canEdit = CanManagePlaylist(ownerId)
    If Not canEdit Then Response.Redirect APP_VROOT & "/playlists.asp?err=denegado"
End If

' --- Procesar el formulario ---
If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    fTitle = FormS("title", LEN_TITLE)
    fType  = FormInt("type", PLAYLIST_PUBLIC)
    fPhoto = FormS("photo", LEN_PATH)
    If fType <> PLAYLIST_PRIVATE Then fType = PLAYLIST_PUBLIC

    ' La portada debe ser una de las imagenes disponibles (lista blanca).
    Dim allowedPhoto, fso, fld, f, okPhoto
    allowedPhoto = "|~/playlistImages/default.jpg|"
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    If fso.FolderExists(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/playlistImages")) Then
        Set fld = fso.GetFolder(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/playlistImages"))
        For Each f In fld.Files
            allowedPhoto = allowedPhoto & "~/playlistImages/" & f.Name & "|"
        Next
    End If
    okPhoto = (InStr(LCase(allowedPhoto), LCase("|" & fPhoto & "|")) > 0)
    If Not okPhoto Then fPhoto = "~/playlistImages/default.jpg"

    If Len(fTitle) < 1 Then
        errMsg = "El titulo de la playlist es obligatorio."
    ElseIf Len(fTitle) > LEN_TITLE Then
        errMsg = "El titulo no puede superar los " & LEN_TITLE & " caracteres."
    ElseIf isEdit Then
        Set p = New DbParams
        p.Add "@t", adVarChar, LEN_TITLE, fTitle
        p.Add "@y", adInteger, 0, fType
        p.Add "@ph", adVarChar, LEN_PATH, fPhoto
        p.Add "@id", adInteger, 0, plId
        If DbExec("UPDATE TBL_PLAYLIST SET TITLE = @t, TYPE = @y, PHOTO = @ph WHERE ID_PLAYLIST = @id", p) Then
            FlashSet "ok", "Playlist actualizada correctamente."
            Response.Redirect APP_VROOT & "/playlist.asp?id=" & plId
        Else
            errMsg = "No se pudo actualizar la playlist: " & LastDbError
        End If
    Else
        Set p = New DbParams
        p.Add "@u", adInteger, 0, CurrentUserId()
        p.Add "@t", adVarChar, LEN_TITLE, fTitle
        p.Add "@y", adInteger, 0, fType
        p.Add "@ph", adVarChar, LEN_PATH, fPhoto
        Dim newId
        newId = DbInsertReturnId("INSERT INTO TBL_PLAYLIST (ID_USER, TITLE, CREATION_DATE, TYPE, PHOTO) " & _
                                 "VALUES (@u, @t, GETDATE(), @y, @ph)", p)
        If newId > 0 Then
            FlashSet "ok", "Playlist creada correctamente."
            Response.Redirect APP_VROOT & "/playlist.asp?id=" & newId
        Else
            errMsg = "No se pudo crear la playlist: " & LastDbError
        End If
    End If
End If

If isEdit Then
    PageTitle = "Editar playlist"
Else
    PageTitle = "Nueva playlist"
End If
%>
<!--#include file="includes/header.asp"-->

<div class="page-head">
    <div>
        <h1><%=H(PageTitle)%></h1>
        <p class="sub">Las playlists publicas son visibles para toda la comunidad; las privadas solo para ti.</p>
    </div>
    <div>
        <a class="btn btn--ghost" href="<%=APP_VROOT%>/playlists.asp">Volver</a>
    </div>
</div>

<div class="panel" style="max-width:720px">
    <% If errMsg <> "" Then %>
        <div class="notice notice--danger"><%=H(errMsg)%></div>
    <% End If %>

    <form method="post" action="<%=APP_VROOT%>/playlist_form.asp<% If isEdit Then %>?id=<%=plId%><% End If %>">
        <%=CsrfField()%>
        <div class="field">
            <label for="title">Titulo de la playlist</label>
            <input type="text" id="title" name="title" maxlength="<%=LEN_TITLE%>" required
                   value="<%=HAttr(fTitle)%>" placeholder="Mis favoritas">
        </div>

        <div class="form-grid">
            <div class="field">
                <label for="type">Visibilidad</label>
                <select id="type" name="type">
                    <option value="<%=PLAYLIST_PUBLIC%>" <% If fType = PLAYLIST_PUBLIC Then Response.Write "selected" %>>
                        Publica - visible para todos
                    </option>
                    <option value="<%=PLAYLIST_PRIVATE%>" <% If fType = PLAYLIST_PRIVATE Then Response.Write "selected" %>>
                        Privada - solo para mi
                    </option>
                </select>
            </div>

            <div class="field">
                <label for="photo">Portada</label>
                <select id="photo" name="photo">
                    <%
                    Dim fso2, fld2, f2, logical
                    Set fso2 = Server.CreateObject("Scripting.FileSystemObject")
                    logical = ""
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
            <button type="submit" class="btn btn--primary">
                <% If isEdit Then %>Guardar cambios<% Else %>Crear playlist<% End If %>
            </button>
            <a class="btn btn--ghost" href="<%=APP_VROOT%>/playlists.asp">Cancelar</a>
        </div>
    </form>
</div>

<!--#include file="includes/footer.asp"-->

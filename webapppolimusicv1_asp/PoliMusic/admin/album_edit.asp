<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include virtual="/PoliMusic/includes/app.asp"-->
<%
' =====================================================================
'  admin/album_edit.asp - Alta y edicion de albumes
'  Incluye la gestion del tracklist (canciones que componen el album).
' =====================================================================
RequireAdmin()

Dim PageTitle, ActiveNav, AdminTab
ActiveNav = "admin"
AdminTab = "albums"

Dim albumId, isEdit, errMsg, p, rs
Dim fTitle, fYear, fImage

albumId = QueryInt("id", 0)
isEdit  = (albumId > 0)
errMsg  = ""
fTitle  = ""
fYear   = Year(Now())
fImage  = "~/albumImages/album1.png"

If isEdit Then
    Set p = New DbParams
    p.Add "@id", adInteger, 0, albumId
    Set rs = DbQuery("SELECT ID_ALBUM, TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH FROM TBL_ALBUM WHERE ID_ALBUM = @id", p)
    If rs Is Nothing Or rs.EOF Then
        Response.Redirect APP_VROOT & "/admin/albums.asp?err=noencontrado"
    End If
    fTitle = CStr(rs("TITLE_ALBUM") & "")
    fYear  = ToInt(rs("RELEASE_YEAR"), Year(Now()))
    fImage = CStr(rs("ALBUM_IMAGE_PATH") & "")
    rs.Close
End If

If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    fTitle = FormS("title_album", LEN_TITLE)
    fYear  = FormInt("release_year", Year(Now()))
    fImage = FormS("album_image", LEN_PATH)

    Dim allowed, fso, fld, f, okImg
    allowed = "|"
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    If fso.FolderExists(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/albumImages")) Then
        Set fld = fso.GetFolder(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/albumImages"))
        For Each f In fld.Files
            allowed = allowed & "~/albumImages/" & f.Name & "|"
        Next
    End If
    okImg = (InStr(LCase(allowed), LCase("|" & fImage & "|")) > 0)
    If Not okImg Then fImage = ""

    If Len(fTitle) < 1 Then
        errMsg = "El titulo del album es obligatorio."
    ElseIf fYear < 1900 Or fYear > 2100 Then
        errMsg = "El año de publicacion debe estar entre 1900 y 2100."
    Else
        Dim newId
        If isEdit Then
            Set p = New DbParams
            p.Add "@t",  adVarChar, LEN_TITLE, fTitle
            p.Add "@y",  adInteger, 0,         fYear
            p.Add "@im", adVarChar, LEN_PATH,  fImage
            p.Add "@id", adInteger, 0,         albumId
            If DbExec("UPDATE TBL_ALBUM SET TITLE_ALBUM = @t, RELEASE_YEAR = @y, ALBUM_IMAGE_PATH = @im WHERE ID_ALBUM = @id", p) Then
                newId = albumId
            Else
                errMsg = "No se pudo actualizar el album: " & LastDbError
            End If
        Else
            Set p = New DbParams
            p.Add "@t",  adVarChar, LEN_TITLE, fTitle
            p.Add "@y",  adInteger, 0,         fYear
            p.Add "@im", adVarChar, LEN_PATH,  fImage
            newId = DbInsertReturnId("INSERT INTO TBL_ALBUM (TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH) " & _
                                     "VALUES (@t, @y, @im)", p)
            If newId <= 0 Then errMsg = "No se pudo crear el album: " & LastDbError
        End If

        If errMsg = "" And newId > 0 Then
            FlashSet "ok", IIf(isEdit, "Album actualizado correctamente.", "Album creado correctamente.")
            Response.Redirect APP_VROOT & "/admin/album_edit.asp?id=" & newId
        End If
    End If
End If

PageTitle = IIf(isEdit, "Editar album", "Nuevo album")

' --- Tracklist actual y canciones disponibles ---
Dim rsTracks, rsAvail
Set rsTracks = Nothing
Set rsAvail  = Nothing
If isEdit Then
    Set p = New DbParams
    p.Add "@id", adInteger, 0, albumId
    Set rsTracks = DbQuery(SQL_ALBUM_SONGS, p)
    Set p = New DbParams
    p.Add "@id", adInteger, 0, albumId
    Set rsAvail = DbQuery("SELECT s.ID_SONG, s.SONG_NAME FROM TBL_SONG s " & _
        "WHERE NOT EXISTS (SELECT 1 FROM TBL_TRACKLIST t WHERE t.ID_ALBUM = @id AND t.ID_SONG = s.ID_SONG) " & _
        "ORDER BY s.SONG_NAME", p)
End If
%>
<!--#include virtual="/PoliMusic/includes/header.asp"-->

<div class="page-head">
    <div>
        <h1><%=H(PageTitle)%></h1>
        <p class="sub">Los datos basicos del album y su tracklist.</p>
    </div>
    <div>
        <a class="btn btn--ghost" href="<%=APP_VROOT%>/admin/albums.asp">Volver</a>
    </div>
</div>

<!--#include file="nav.asp"-->

<div class="panel" style="max-width:820px">
    <% If errMsg <> "" Then %>
        <div class="notice notice--danger"><%=H(errMsg)%></div>
    <% End If %>

    <form method="post" action="<%=APP_VROOT%>/admin/album_edit.asp<% If isEdit Then %>?id=<%=albumId%><% End If %>">
        <%=CsrfField()%>

        <div class="form-grid">
            <div class="field">
                <label for="title_album">Titulo del album</label>
                <input type="text" id="title_album" name="title_album" maxlength="<%=LEN_TITLE%>" required value="<%=HAttr(fTitle)%>">
            </div>
            <div class="field">
                <label for="release_year">Año de publicacion</label>
                <input type="number" id="release_year" name="release_year" min="1900" max="2100" value="<%=HAttr(fYear)%>">
            </div>
        </div>

        <div class="field">
            <label for="album_image">Portada</label>
            <select id="album_image" name="album_image">
                <option value="">-- Sin portada --</option>
                <%
                Dim fso2, fld2, f2, logical
                Set fso2 = Server.CreateObject("Scripting.FileSystemObject")
                If fso2.FolderExists(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/albumImages")) Then
                    Set fld2 = fso2.GetFolder(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/albumImages"))
                    For Each f2 In fld2.Files
                        logical = "~/albumImages/" & f2.Name
                        Response.Write "<option value=""" & HAttr(logical) & """"
                        If LCase(logical) = LCase(fImage) Then Response.Write " selected"
                        Response.Write ">" & H(f2.Name) & "</option>"
                    Next
                End If
                %>
            </select>
        </div>

        <div class="form-actions">
            <button type="submit" class="btn btn--primary"><% If isEdit Then %>Guardar cambios<% Else %>Crear album<% End If %></button>
            <a class="btn btn--ghost" href="<%=APP_VROOT%>/admin/albums.asp">Cancelar</a>
        </div>
    </form>
</div>

<% If isEdit Then %>
<div class="panel" style="max-width:820px">
    <h2>Tracklist</h2>
    <%
    If rsTracks Is Nothing Or rsTracks.EOF Then
        Response.Write "<p class=""sub"">El album todavia no tiene canciones.</p>"
    Else
        Response.Write "<div class=""table-wrap""><table class=""data""><thead><tr>" & _
                       "<th>#</th><th>Cancion</th><th>Artistas</th><th>Reproducciones</th><th></th>" & _
                       "</tr></thead><tbody>"
        Dim tn
        tn = 0
        Do While Not rsTracks.EOF
            tn = tn + 1
            Response.Write "<tr><td>" & tn & "</td>" & _
                           "<td>" & H(rsTracks("SONG_NAME")) & "</td>" & _
                           "<td>" & H(rsTracks("ARTISTS")) & "</td>" & _
                           "<td>" & H(rsTracks("PLAYS")) & "</td>" & _
                           "<td class=""actions"">" & _
                           MiniForm(APP_VROOT & "/admin/album_track.asp", _
                              Hidden("action", "remove") & Hidden("album_id", albumId) & Hidden("song_id", rsTracks("ID_SONG")), _
                              "Quitar", "btn btn--danger btn--sm", "Quitar la cancion del album?", "trash") & _
                           "</td></tr>"
            rsTracks.MoveNext
        Loop
        Response.Write "</tbody></table></div>"
    End If
    %>

    <h3 style="margin-top:20px">Anadir cancion al album</h3>
    <%
    If rsAvail Is Nothing Or rsAvail.EOF Then
        Response.Write "<p class=""sub"">Todas las canciones del catalogo ya estan en este album.</p>"
    Else
    %>
    <form method="post" action="<%=APP_VROOT%>/admin/album_track.asp">
        <%=CsrfField()%>
        <%=Hidden("action", "add")%>
        <%=Hidden("album_id", albumId)%>
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
                <button type="submit" class="btn btn--primary">+ Anadir al album</button>
            </div>
        </div>
    </form>
    <% End If %>
</div>
<% End If %>

<!--#include virtual="/PoliMusic/includes/footer.asp"-->

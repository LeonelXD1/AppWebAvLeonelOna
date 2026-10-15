<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include virtual="/PoliMusic/includes/app.asp"-->
<%
' =====================================================================
'  admin/artist_edit.asp - Alta y edicion de artistas
' =====================================================================
RequireAdmin()

Dim PageTitle, ActiveNav, AdminTab
ActiveNav = "admin"
AdminTab = "artists"

Dim artistId, isEdit, errMsg, p, rs
Dim fName, fLast, fImage

artistId = QueryInt("id", 0)
isEdit   = (artistId > 0)
errMsg   = ""
fName    = ""
fLast    = ""
fImage   = "~/artistImages/artist1.jpg"

If isEdit Then
    Set p = New DbParams
    p.Add "@id", adInteger, 0, artistId
    Set rs = DbQuery("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE FROM TBL_ARTIST WHERE ID_ARTIST = @id", p)
    If rs Is Nothing Or rs.EOF Then
        Response.Redirect APP_VROOT & "/admin/artists.asp?err=noencontrado"
    End If
    fName  = CStr(rs("ARTIST_NAME") & "")
    fLast  = CStr(rs("ARTIST_LASTNAME") & "")
    fImage = CStr(rs("ARTIST_IMAGE") & "")
    rs.Close
End If

If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    fName  = FormS("artist_name", LEN_ARTIST)
    fLast  = FormS("artist_lastname", LEN_ARTIST)
    fImage = FormS("artist_image", LEN_PATH)

    ' Lista blanca de imagenes de artista.
    Dim allowed, fso, fld, f, okImg
    allowed = "|"
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    If fso.FolderExists(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/artistImages")) Then
        Set fld = fso.GetFolder(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/artistImages"))
        For Each f In fld.Files
            allowed = allowed & "~/artistImages/" & f.Name & "|"
        Next
    End If
    okImg = (InStr(LCase(allowed), LCase("|" & fImage & "|")) > 0)
    If Not okImg Then fImage = ""

    If Len(fName) < 1 Then
        errMsg = "El nombre del artista es obligatorio."
    Else
        Dim newId
        If isEdit Then
            Set p = New DbParams
            p.Add "@n",  adVarChar, LEN_ARTIST, fName
            p.Add "@l",  adVarChar, LEN_ARTIST, fLast
            p.Add "@im", adVarChar, LEN_PATH,   fImage
            p.Add "@id", adInteger, 0,          artistId
            If DbExec("UPDATE TBL_ARTIST SET ARTIST_NAME = @n, ARTIST_LASTNAME = @l, ARTIST_IMAGE = @im WHERE ID_ARTIST = @id", p) Then
                newId = artistId
            Else
                errMsg = "No se pudo actualizar el artista: " & LastDbError
            End If
        Else
            Set p = New DbParams
            p.Add "@n",  adVarChar, LEN_ARTIST, fName
            p.Add "@l",  adVarChar, LEN_ARTIST, fLast
            p.Add "@im", adVarChar, LEN_PATH,   fImage
            newId = DbInsertReturnId("INSERT INTO TBL_ARTIST (ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE) " & _
                                     "VALUES (@n, @l, @im)", p)
            If newId <= 0 Then errMsg = "No se pudo crear el artista: " & LastDbError
        End If

        If errMsg = "" And newId > 0 Then
            FlashSet "ok", IIf(isEdit, "Artista actualizado correctamente.", "Artista creado correctamente.")
            Response.Redirect APP_VROOT & "/admin/artists.asp"
        End If
    End If
End If

PageTitle = IIf(isEdit, "Editar artista", "Nuevo artista")
%>
<!--#include virtual="/PoliMusic/includes/header.asp"-->

<div class="page-head">
    <div>
        <h1><%=H(PageTitle)%></h1>
        <p class="sub">Los artistas se asocian a las canciones desde la ficha de cada cancion.</p>
    </div>
    <div>
        <a class="btn btn--ghost" href="<%=APP_VROOT%>/admin/artists.asp">Volver</a>
    </div>
</div>

<!--#include file="nav.asp"-->

<div class="panel" style="max-width:720px">
    <% If errMsg <> "" Then %>
        <div class="notice notice--danger"><%=H(errMsg)%></div>
    <% End If %>

    <form method="post" action="<%=APP_VROOT%>/admin/artist_edit.asp<% If isEdit Then %>?id=<%=artistId%><% End If %>">
        <%=CsrfField()%>

        <div class="form-grid">
            <div class="field">
                <label for="artist_name">Nombre</label>
                <input type="text" id="artist_name" name="artist_name" maxlength="<%=LEN_ARTIST%>" required value="<%=HAttr(fName)%>">
            </div>
            <div class="field">
                <label for="artist_lastname">Apellido</label>
                <input type="text" id="artist_lastname" name="artist_lastname" maxlength="<%=LEN_ARTIST%>" value="<%=HAttr(fLast)%>">
            </div>
        </div>

        <div class="field">
            <label for="artist_image">Imagen</label>
            <select id="artist_image" name="artist_image">
                <option value="">-- Sin imagen --</option>
                <%
                Dim fso2, fld2, f2, logical
                Set fso2 = Server.CreateObject("Scripting.FileSystemObject")
                If fso2.FolderExists(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/artistImages")) Then
                    Set fld2 = fso2.GetFolder(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/artistImages"))
                    For Each f2 In fld2.Files
                        logical = "~/artistImages/" & f2.Name
                        Response.Write "<option value=""" & HAttr(logical) & """"
                        If LCase(logical) = LCase(fImage) Then Response.Write " selected"
                        Response.Write ">" & H(f2.Name) & "</option>"
                    Next
                End If
                %>
            </select>
            <div class="hint">Las imagenes disponibles estan en <code>assets/artistImages</code>.</div>
        </div>

        <div class="form-actions">
            <button type="submit" class="btn btn--primary"><% If isEdit Then %>Guardar cambios<% Else %>Crear artista<% End If %></button>
            <a class="btn btn--ghost" href="<%=APP_VROOT%>/admin/artists.asp">Cancelar</a>
        </div>
    </form>
</div>

<!--#include virtual="/PoliMusic/includes/footer.asp"-->

<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  profile.asp - Perfil del usuario en sesion (consulta y edicion)
' =====================================================================
RequireLogin()

Dim PageTitle, ActiveNav
PageTitle = "Mi perfil"
ActiveNav = "profile"

Dim p, rs, errMsg, okMsg
Dim fEmail, fBirthday, fPhoto
Dim uName, uType, uCreated

errMsg = ""
okMsg = ""

' --- Acciones POST ---
If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    fEmail    = FormS("email", LEN_EMAIL)
    fBirthday = FormS("birthday", 10)
    fPhoto    = FormS("photo", LEN_PATH)

    If Not IsValidEmail(fEmail) Then
        errMsg = "El correo electronico no tiene un formato valido."
    ElseIf fBirthday <> "" And IsNull(ParseIsoDate(fBirthday)) Then
        errMsg = "La fecha de nacimiento no es valida."
    Else
        ' Lista blanca de avatares disponibles.
        Dim allowed, fso, fld, f, okPhoto
        allowed = "|~/userImages/default.jpg|"
        Set fso = Server.CreateObject("Scripting.FileSystemObject")
        If fso.FolderExists(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/userImages")) Then
            Set fld = fso.GetFolder(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/userImages"))
            For Each f In fld.Files
                allowed = allowed & "~/userImages/" & f.Name & "|"
            Next
        End If
        okPhoto = (InStr(LCase(allowed), LCase("|" & fPhoto & "|")) > 0)
        If Not okPhoto Then fPhoto = "~/userImages/default.jpg"

        Set p = New DbParams
        p.Add "@e",  adVarChar, LEN_EMAIL, fEmail
        p.Add "@b",  adDBTimeStamp, 0, ParseIsoDate(fBirthday)
        p.Add "@ph", adVarChar, LEN_PATH, fPhoto
        p.Add "@id", adInteger, 0, CurrentUserId()
        If DbExec("UPDATE TBL_USER SET EMAIL = @e, BIRTHDAY = @b, USER_PHOTO = @ph WHERE ID_USER = @id", p) Then
            Session("user_email") = fEmail
            Session("user_photo") = fPhoto
            FlashSet "ok", "Perfil actualizado correctamente."
            Response.Redirect APP_VROOT & "/profile.asp"
        Else
            errMsg = "No se pudo actualizar el perfil: " & LastDbError
        End If
    End If
End If

' --- Datos actuales ---
Set p = New DbParams
p.Add "@id", adInteger, 0, CurrentUserId()
Set rs = DbQuery("SELECT USERNAME, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE FROM TBL_USER WHERE ID_USER = @id", p)
If rs Is Nothing Or rs.EOF Then
    Response.Redirect APP_VROOT & "/logout.asp"
End If
uName     = CStr(rs("USERNAME") & "")
fEmail    = CStr(rs("EMAIL") & "")
fBirthday = FmtDateInput(rs("BIRTHDAY"))
fPhoto    = CStr(rs("USER_PHOTO") & "")
uType     = CInt(rs("USER_TYPE"))
rs.Close

' --- Actividad del usuario ---
Dim plCount, favArtists
Set p = New DbParams
p.Add "@u", adInteger, 0, CurrentUserId()
plCount = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE ID_USER = @u", p), 0)
%>
<!--#include file="includes/header.asp"-->

<div class="page-head">
    <div>
        <h1>Mi perfil</h1>
        <p class="sub">Actualiza tus datos de contacto y tu avatar.</p>
    </div>
</div>

<div class="hero" style="align-items:center">
    <img class="hero__art hero__art--round" src="<%=HAttr(UserPhoto(fPhoto))%>" alt="Avatar" style="width:150px;height:150px">
    <div class="hero__meta">
        <div class="hero__eyebrow">Cuenta</div>
        <h1><%=H(uName)%></h1>
        <div class="hero__facts">
            <span class="tag <% If uType = USER_TYPE_ADMIN Then %>tag--accent<% End If %>">
                <%=H(UserTypeName(uType))%>
            </span>
            <span class="dot">&bull;</span>
            <span><%=plCount%> playlists propias</span>
            <span class="dot">&bull;</span>
            <span><%=H(fEmail)%></span>
        </div>
    </div>
</div>

<div class="panel" style="max-width:720px">
    <% If errMsg <> "" Then %>
        <div class="notice notice--danger"><%=H(errMsg)%></div>
    <% End If %>

    <h2>Datos de la cuenta</h2>
    <form method="post" action="<%=APP_VROOT%>/profile.asp">
        <%=CsrfField()%>

        <div class="field">
            <label>Usuario</label>
            <input type="text" value="<%=HAttr(uName)%>" disabled>
            <div class="hint">El nombre de usuario no se puede modificar.</div>
        </div>

        <div class="form-grid">
            <div class="field">
                <label for="email">Correo electronico</label>
                <input type="email" id="email" name="email" maxlength="<%=LEN_EMAIL%>" required
                       value="<%=HAttr(fEmail)%>">
            </div>
            <div class="field">
                <label for="birthday">Fecha de nacimiento</label>
                <input type="date" id="birthday" name="birthday" value="<%=HAttr(fBirthday)%>">
            </div>
        </div>

        <div class="field">
            <label for="photo">Avatar</label>
            <select id="photo" name="photo">
                <%
                Dim fso2, fld2, f2, logical
                Set fso2 = Server.CreateObject("Scripting.FileSystemObject")
                If fso2.FolderExists(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/userImages")) Then
                    Set fld2 = fso2.GetFolder(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/userImages"))
                    For Each f2 In fld2.Files
                        logical = "~/userImages/" & f2.Name
                        Response.Write "<option value=""" & HAttr(logical) & """"
                        If LCase(logical) = LCase(fPhoto) Then Response.Write " selected"
                        Response.Write ">" & H(f2.Name) & "</option>"
                    Next
                End If
                %>
            </select>
        </div>

        <div class="form-actions">
            <button type="submit" class="btn btn--primary">Guardar cambios</button>
            <a class="btn btn--ghost" href="<%=APP_VROOT%>/home.asp">Cancelar</a>
        </div>
    </form>
</div>

<!--#include file="includes/footer.asp"-->

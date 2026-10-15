<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include virtual="/PoliMusic/includes/app.asp"-->
<%
' =====================================================================
'  admin/user_edit.asp - Alta y edicion de usuarios
'  Las contrasenas se almacenan siempre como SHA-1 hexadecimal,
'  calculado por SQL Server (HASHBYTES) al ejecutar la consulta.
' =====================================================================
RequireAdmin()

Dim PageTitle, ActiveNav, AdminTab
ActiveNav = "admin"
AdminTab = "users"

Dim userId, isEdit, errMsg, p, rs
Dim fUser, fEmail, fBday, fPhoto, fType, fPass, fPass2

userId = QueryInt("id", 0)
isEdit = (userId > 0)
errMsg = ""
fUser  = ""
fEmail = ""
fBday  = ""
fPhoto = "~/userImages/default.jpg"
fType  = USER_TYPE_STANDARD

If isEdit Then
    Set p = New DbParams
    p.Add "@id", adInteger, 0, userId
    Set rs = DbQuery("SELECT ID_USER, USERNAME, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE FROM TBL_USER WHERE ID_USER = @id", p)
    If rs Is Nothing Or rs.EOF Then
        Response.Redirect APP_VROOT & "/admin/users.asp?err=noencontrado"
    End If
    fUser  = CStr(rs("USERNAME") & "")
    fEmail = CStr(rs("EMAIL") & "")
    fBday  = FmtDateInput(rs("BIRTHDAY"))
    fPhoto = CStr(rs("USER_PHOTO") & "")
    fType  = CInt(rs("USER_TYPE"))
    rs.Close
End If

If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    fUser  = FormS("username", LEN_USER)
    fEmail = FormS("email", LEN_EMAIL)
    fBday  = FormS("birthday", 10)
    fPhoto = FormS("photo", LEN_PATH)
    fType  = FormInt("user_type", USER_TYPE_STANDARD)
    fPass  = FormS("password", LEN_PASS)
    fPass2 = FormS("password2", LEN_PASS)
    If fType <> USER_TYPE_ADMIN Then fType = USER_TYPE_STANDARD

    ' Lista blanca de avatares.
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

    ' Nombre de usuario unico (excluyendo el propio registro).
    Dim dupSql, dup
    If isEdit Then
        Set p = New DbParams
        p.Add "@u", adVarChar, LEN_USER, fUser
        p.Add "@id", adInteger, 0, userId
        dup = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE USERNAME = @u AND ID_USER <> @id", p), 0)
    Else
        Set p = New DbParams
        p.Add "@u", adVarChar, LEN_USER, fUser
        dup = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE USERNAME = @u", p), 0)
    End If

    ' No se puede degradar al ultimo administrador.
    Dim adminsLeft, wouldLoseAdmin
    adminsLeft = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE USER_TYPE = " & USER_TYPE_ADMIN, Nothing), 0)
    wouldLoseAdmin = (isEdit And fType <> USER_TYPE_ADMIN And adminsLeft <= 1)

    If Not IsValidUsername(fUser) Then
        errMsg = "El usuario debe tener entre 3 y 50 caracteres (letras, numeros, punto, guion o guion bajo)."
    ElseIf dup > 0 Then
        errMsg = "Ya existe otro usuario con ese nombre."
    ElseIf Not IsValidEmail(fEmail) Then
        errMsg = "El correo electronico no tiene un formato valido."
    ElseIf fBday <> "" And IsNull(ParseIsoDate(fBday)) Then
        errMsg = "La fecha de nacimiento no es valida."
    ElseIf wouldLoseAdmin Then
        errMsg = "Debe existir al menos un administrador en el sistema."
    ElseIf (Not isEdit) And Len(fPass) < 6 Then
        errMsg = "La contrasena debe tener al menos 6 caracteres."
    ElseIf fPass <> "" And Len(fPass) < 6 Then
        errMsg = "La nueva contrasena debe tener al menos 6 caracteres."
    ElseIf fPass <> fPass2 Then
        errMsg = "Las contrasenas no coinciden."
    Else
        Dim newId, okOp
        okOp = False
        If isEdit Then
            If fPass = "" Then
                Set p = New DbParams
                p.Add "@u",  adVarChar, LEN_USER,  fUser
                p.Add "@e",  adVarChar, LEN_EMAIL, fEmail
                p.Add "@b",  adDBTimeStamp, 0,     ParseIsoDate(fBday)
                p.Add "@ph", adVarChar, LEN_PATH,  fPhoto
                p.Add "@t",  adInteger, 0,         fType
                p.Add "@id", adInteger, 0,         userId
                okOp = DbExec("UPDATE TBL_USER SET USERNAME = @u, EMAIL = @e, BIRTHDAY = @b, " & _
                              "USER_PHOTO = @ph, USER_TYPE = @t WHERE ID_USER = @id", p)
            Else
                Set p = New DbParams
                p.Add "@u",  adVarChar, LEN_USER,  fUser
                p.Add "@pw", adVarChar, LEN_PASS,  fPass
                p.Add "@e",  adVarChar, LEN_EMAIL, fEmail
                p.Add "@b",  adDBTimeStamp, 0,     ParseIsoDate(fBday)
                p.Add "@ph", adVarChar, LEN_PATH,  fPhoto
                p.Add "@t",  adInteger, 0,         fType
                p.Add "@id", adInteger, 0,         userId
                okOp = DbExec("UPDATE TBL_USER SET USERNAME = @u, " & _
                              "PASSWORD = CONVERT(varchar(40), HASHBYTES('SHA1', @pw), 2), " & _
                              "EMAIL = @e, BIRTHDAY = @b, USER_PHOTO = @ph, USER_TYPE = @t " & _
                              "WHERE ID_USER = @id", p)
            End If
            newId = userId
            If Not okOp Then errMsg = "No se pudo actualizar el usuario: " & LastDbError
        Else
            Set p = New DbParams
            p.Add "@u",  adVarChar, LEN_USER,  fUser
            p.Add "@pw", adVarChar, LEN_PASS,  fPass
            p.Add "@e",  adVarChar, LEN_EMAIL, fEmail
            p.Add "@b",  adDBTimeStamp, 0,     ParseIsoDate(fBday)
            p.Add "@ph", adVarChar, LEN_PATH,  fPhoto
            p.Add "@t",  adInteger, 0,         fType
            newId = DbInsertReturnId("INSERT INTO TBL_USER (USERNAME, PASSWORD, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE) " & _
                                     "VALUES (@u, CONVERT(varchar(40), HASHBYTES('SHA1', @pw), 2), @e, @b, @ph, @t)", p)
            If newId <= 0 Then errMsg = "No se pudo crear el usuario: " & LastDbError
        End If

        If errMsg = "" And newId > 0 Then
            ' Si el administrador edita su propia cuenta, refresca la sesion.
            If isEdit And userId = CurrentUserId() Then
                Session("user_name")  = fUser
                Session("user_email") = fEmail
                Session("user_photo") = fPhoto
                Session("user_type")  = fType
            End If
            FlashSet "ok", IIf(isEdit, "Usuario actualizado correctamente.", "Usuario creado correctamente.")
            Response.Redirect APP_VROOT & "/admin/users.asp"
        End If
    End If
End If

PageTitle = IIf(isEdit, "Editar usuario", "Nuevo usuario")
%>
<!--#include virtual="/PoliMusic/includes/header.asp"-->

<div class="page-head">
    <div>
        <h1><%=H(PageTitle)%></h1>
        <p class="sub">Los perfiles determinan los permisos: el administrador gestiona todo el sistema.</p>
    </div>
    <div>
        <a class="btn btn--ghost" href="<%=APP_VROOT%>/admin/users.asp">Volver</a>
    </div>
</div>

<!--#include file="nav.asp"-->

<div class="panel" style="max-width:820px">
    <% If errMsg <> "" Then %>
        <div class="notice notice--danger"><%=H(errMsg)%></div>
    <% End If %>

    <form method="post" action="<%=APP_VROOT%>/admin/user_edit.asp<% If isEdit Then %>?id=<%=userId%><% End If %>">
        <%=CsrfField()%>

        <div class="form-grid">
            <div class="field">
                <label for="username">Usuario</label>
                <input type="text" id="username" name="username" maxlength="<%=LEN_USER%>" required value="<%=HAttr(fUser)%>">
            </div>
            <div class="field">
                <label for="user_type">Perfil de acceso</label>
                <select id="user_type" name="user_type">
                    <option value="<%=USER_TYPE_STANDARD%>" <% If fType = USER_TYPE_STANDARD Then Response.Write "selected" %>>
                        Usuario estandar
                    </option>
                    <option value="<%=USER_TYPE_ADMIN%>" <% If fType = USER_TYPE_ADMIN Then Response.Write "selected" %>>
                        Administrador
                    </option>
                </select>
            </div>
        </div>

        <div class="form-grid">
            <div class="field">
                <label for="password">Contrasena <% If isEdit Then %>(dejar vacio para no cambiarla)<% End If %></label>
                <input type="password" id="password" name="password" maxlength="<%=LEN_PASS%>"
                       <% If Not isEdit Then %>required<% End If %> autocomplete="new-password">
            </div>
            <div class="field">
                <label for="password2">Repetir contrasena</label>
                <input type="password" id="password2" name="password2" maxlength="<%=LEN_PASS%>" autocomplete="new-password">
            </div>
        </div>

        <div class="form-grid">
            <div class="field">
                <label for="email">Correo electronico</label>
                <input type="email" id="email" name="email" maxlength="<%=LEN_EMAIL%>" required value="<%=HAttr(fEmail)%>">
            </div>
            <div class="field">
                <label for="birthday">Fecha de nacimiento</label>
                <input type="date" id="birthday" name="birthday" value="<%=HAttr(fBday)%>">
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
            <button type="submit" class="btn btn--primary"><% If isEdit Then %>Guardar cambios<% Else %>Crear usuario<% End If %></button>
            <a class="btn btn--ghost" href="<%=APP_VROOT%>/admin/users.asp">Cancelar</a>
        </div>
    </form>
</div>

<!--#include virtual="/PoliMusic/includes/footer.asp"-->

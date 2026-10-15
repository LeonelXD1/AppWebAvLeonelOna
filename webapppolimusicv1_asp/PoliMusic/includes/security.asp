<%
' =====================================================================
'  PoliMusic - includes/security.asp
'  Sesiones, autenticacion, control de acceso por perfil y CSRF.
' =====================================================================

' ---------------------------------------------------------------------
'  Estado de la sesion
' ---------------------------------------------------------------------
Function CurrentUserId()
    CurrentUserId = ToInt(Session("user_id"), 0)
End Function

Function CurrentUsername()
    CurrentUsername = S(Session("user_name"), LEN_USER)
End Function

Function CurrentUserType()
    CurrentUserType = ToInt(Session("user_type"), USER_TYPE_STANDARD)
End Function

Function CurrentUserPhoto()
    CurrentUserPhoto = CStr(Session("user_photo") & "")
End Function

Function IsAuthenticated()
    IsAuthenticated = (CurrentUserId() > 0) And (Len(CStr(Session("auth_token") & "")) > 0)
End Function

Function IsAdmin()
    IsAdmin = IsAuthenticated() And (CurrentUserType() = USER_TYPE_ADMIN)
End Function

' Propietario de un recurso concreto.
Function IsOwner(ownerId)
    IsOwner = IsAuthenticated() And (ToInt(ownerId, -1) = CurrentUserId())
End Function

' Regla de negocio: un usuario estandar solo gestiona sus playlists;
' el administrador gestiona todas.
Function CanManagePlaylist(ownerId)
    CanManagePlaylist = IsAdmin() Or IsOwner(ownerId)
End Function

' ---------------------------------------------------------------------
'  Guardas de acceso
' ---------------------------------------------------------------------
Sub RequireLogin()
    If Not IsAuthenticated() Then
        Response.Redirect APP_VROOT & "/login.asp?msg=sesion"
    End If
End Sub

Sub RequireAdmin()
    If Not IsAuthenticated() Then
        Response.Redirect APP_VROOT & "/login.asp?msg=sesion"
    ElseIf Not IsAdmin() Then
        Response.Redirect APP_VROOT & "/home.asp?err=denegado"
    End If
End Sub

' ---------------------------------------------------------------------
'  CSRF: token por sesion incrustado en cada formulario POST.
' ---------------------------------------------------------------------
Function CsrfToken()
    If Len(CStr(Session("csrf_token") & "")) = 0 Then
        Session("csrf_token") = NewToken()
    End If
    CsrfToken = CStr(Session("csrf_token"))
End Function

Function CsrfField()
    CsrfField = "<input type=""hidden"" name=""csrf"" value=""" & CsrfToken() & """>"
End Function

' Comprobacion no destructiva (para endpoints de datos).
Function CsrfValid()
    Dim sent, expected
    sent = CStr(Request.Form("csrf") & "")
    expected = CStr(Session("csrf_token") & "")
    CsrfValid = (expected <> "" And sent <> "" And sent = expected)
End Function

Sub CsrfCheck()
    If Not CsrfValid() Then
        Response.Status = "403 Forbidden"
        Response.Write "<!DOCTYPE html><html lang=""es""><head><meta charset=""utf-8"">" & _
                       "<meta name=""viewport"" content=""width=device-width, initial-scale=1"">" & _
                       "<title>403 &middot; " & H(APP_NAME) & "</title>" & _
                       "<link rel=""stylesheet"" href=""" & APP_VROOT & "/assets/css/style.css""></head>" & _
                       "<body class=""error-page""><div>" & _
                       "<h1>403</h1><p>La solicitud no es valida o el token de seguridad ha caducado.</p>" & _
                       "<a class=""btn btn--primary"" href=""" & APP_VROOT & "/home.asp"">Volver al inicio</a>" & _
                       "</div></body></html>"
        Response.End
    End If
End Sub

' ---------------------------------------------------------------------
'  Autenticacion. Admite contrasenas en texto plano (datos heredados)
'  y en SHA-1 hexadecimal, comparando siempre mediante parametros.
' ---------------------------------------------------------------------
Function Authenticate(username, password)
    Dim rs, p
    Authenticate = False
    Set p = New DbParams
    p.Add "@u",  adVarChar, LEN_USER, username
    p.Add "@p",  adVarChar, LEN_PASS, password
    p.Add "@p2", adVarChar, LEN_PASS, password
    Set rs = DbQuery( _
        "SELECT TOP 1 ID_USER, USERNAME, USER_TYPE, USER_PHOTO, EMAIL, BIRTHDAY " & _
        "FROM TBL_USER " & _
        "WHERE USERNAME = @u AND (PASSWORD = @p " & _
        "   OR PASSWORD = CONVERT(varchar(40), HASHBYTES('SHA1', @p2), 2))", p)
    If rs Is Nothing Then Exit Function
    If Not rs.EOF Then
        Session("user_id")    = CLng(rs("ID_USER"))
        Session("user_name")  = CStr(rs("USERNAME") & "")
        Session("user_type")  = CInt(rs("USER_TYPE"))
        Session("user_photo") = CStr(rs("USER_PHOTO") & "")
        Session("user_email") = CStr(rs("EMAIL") & "")
        Session("auth_token") = NewToken()
        Session("login_time") = Now()
        Session("csrf_token") = NewToken()
        Authenticate = True
    End If
    rs.Close
End Function

' ---------------------------------------------------------------------
'  Registro de usuario estandar. La contrasena se almacena como SHA-1
'  hexadecimal (mismo formato que los datos existentes).
' ---------------------------------------------------------------------
Function RegisterUser(username, password, email, birthday)
    Dim p, ok
    RegisterUser = False
    Set p = New DbParams
    p.Add "@u",  adVarChar, LEN_USER,  username
    p.Add "@p",  adVarChar, LEN_PASS,  password
    p.Add "@e",  adVarChar, LEN_EMAIL, email
    p.Add "@b",  adDBTimeStamp, 0,     birthday
    p.Add "@ph", adVarChar, LEN_PATH,  "~/userImages/default.jpg"
    p.Add "@t",  adInteger, 0,         USER_TYPE_STANDARD
    ok = DbExec( _
        "INSERT INTO TBL_USER (USERNAME, PASSWORD, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE) " & _
        "VALUES (@u, CONVERT(varchar(40), HASHBYTES('SHA1', @p), 2), @e, @b, @ph, @t)", p)
    RegisterUser = ok
End Function

' ---------------------------------------------------------------------
'  UsernameAvailable: comprobacion previa al registro.
' ---------------------------------------------------------------------
Function UsernameAvailable(username)
    Dim p, v
    Set p = New DbParams
    p.Add "@u", adVarChar, LEN_USER, username
    v = DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE USERNAME = @u", p)
    If IsNull(v) Then
        UsernameAvailable = False
    Else
        UsernameAvailable = (CLng(v) = 0)
    End If
End Function

' ---------------------------------------------------------------------
'  Cierre de sesion: se vacia y destruye la sesion.
' ---------------------------------------------------------------------
Sub DoLogout()
    Session.Contents.RemoveAll()
    Session.Abandon()
End Sub

' ---------------------------------------------------------------------
'  Mensajes flash (un solo uso, guardados en sesion).
' ---------------------------------------------------------------------
Sub FlashSet(kind, text)
    Session("flash_kind") = kind
    Session("flash_text") = text
End Sub

Function FlashRender()
    Dim k, t, iconName
    FlashRender = ""
    k = CStr(Session("flash_kind") & "")
    t = CStr(Session("flash_text") & "")
    Session("flash_kind") = ""
    Session("flash_text") = ""
    If t = "" Then Exit Function

    Select Case LCase(k)
        Case "ok"      : iconName = "check"   : k = "success"
        Case "error"   : iconName = "warning" : k = "danger"
        Case "warn"    : iconName = "warning" : k = "warning"
        Case Else      : iconName = "info"    : k = "info"
    End Select
    FlashRender = Notice(k, iconName, t)
End Function
%>

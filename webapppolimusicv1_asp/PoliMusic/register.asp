<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  register.asp - Registro de usuario estandar (USER_TYPE = 0)
' =====================================================================
Dim errMsg, okMsg
Dim u, e, p1, p2, bdayRaw, bday
Dim fUser, fEmail, fBday

errMsg = ""
okMsg = ""
fUser = ""
fEmail = ""
fBday = ""

If IsAuthenticated() Then Response.Redirect APP_VROOT & "/home.asp"

If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    u       = FormS("username", LEN_USER)
    e       = FormS("email", LEN_EMAIL)
    p1      = FormS("password", LEN_PASS)
    p2      = FormS("password2", LEN_PASS)
    bdayRaw = FormS("birthday", 10)
    fUser = u : fEmail = e : fBday = bdayRaw

    If Not IsValidUsername(u) Then
        errMsg = "El usuario debe tener entre 3 y 50 caracteres (letras, numeros, punto, guion o guion bajo)."
    ElseIf Not IsValidEmail(e) Then
        errMsg = "El correo electronico no tiene un formato valido."
    ElseIf Len(p1) < 6 Then
        errMsg = "La contrasena debe tener al menos 6 caracteres."
    ElseIf p1 <> p2 Then
        errMsg = "Las contrasenas no coinciden."
    ElseIf bdayRaw <> "" And IsNull(ParseIsoDate(bdayRaw)) Then
        errMsg = "La fecha de nacimiento no es valida."
    ElseIf Not UsernameAvailable(u) Then
        errMsg = "Ese nombre de usuario ya esta en uso."
    Else
        bday = ParseIsoDate(bdayRaw)
        If RegisterUser(u, p1, e, bday) Then
            Response.Redirect APP_VROOT & "/login.asp?msg=registro"
        Else
            errMsg = "No se pudo crear la cuenta. Intenta nuevamente."
        End If
    End If
End If
%><!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <meta name="color-scheme" content="light dark">
    <title>Crear cuenta &middot; <%=H(APP_NAME)%></title>
    <%' Se aplica el tema antes del primer pintado para evitar el destello del tema equivocado. %>
    <script>
        (function () {
            try {
                var t = localStorage.getItem("polimusic.theme");
                if (t === "light" || t === "dark") {
                    document.documentElement.setAttribute("data-theme", t);
                }
            } catch (e) { }
        })();
    </script>
    <link rel="stylesheet" href="<%=APP_VROOT%>/assets/css/style.css">
    <link rel="icon" href="<%=APP_VROOT%>/assets/img/favicon.svg" type="image/svg+xml">
</head>
<body class="auth">
    <div class="auth__card">
        <div class="brand">
            <span class="brand__mark"><%=Icon("music", 20)%></span>
            <span class="brand__text"><b><%=H(APP_NAME)%></b><span><%=H(APP_TAGLINE)%></span></span>
        </div>
        <h1>Crear cuenta</h1>
        <p class="auth__lead">Registro de usuario estandar</p>

        <% If errMsg <> "" Then %>
            <div class="notice notice--danger"><%=H(errMsg)%></div>
        <% End If %>
        <% If okMsg <> "" Then %>
            <div class="notice notice--success"><%=H(okMsg)%></div>
        <% End If %>

        <form method="post" action="<%=APP_VROOT%>/register.asp" autocomplete="off">
            <%=CsrfField()%>
            <div class="field">
                <label for="username">Usuario</label>
                <input type="text" id="username" name="username" maxlength="50" required
                       value="<%=HAttr(fUser)%>" placeholder="mi_usuario">
            </div>
            <div class="field">
                <label for="email">Correo electronico</label>
                <input type="email" id="email" name="email" maxlength="50" required
                       value="<%=HAttr(fEmail)%>" placeholder="usuario@epn.edu.ec">
            </div>
            <div class="field">
                <label for="birthday">Fecha de nacimiento (opcional)</label>
                <input type="date" id="birthday" name="birthday" value="<%=HAttr(fBday)%>">
            </div>
            <div class="form-grid">
                <div class="field">
                    <label for="password">Contrasena</label>
                    <input type="password" id="password" name="password" maxlength="50" required placeholder="Minimo 6 caracteres">
                </div>
                <div class="field">
                    <label for="password2">Repetir contrasena</label>
                    <input type="password" id="password2" name="password2" maxlength="50" required>
                </div>
            </div>
            <button type="submit" class="btn btn--primary btn--block btn--lg"><%=Icon("plus", 17)%><span>Crear cuenta</span></button>
        </form>

        <p class="auth__alt">Ya tienes cuenta? <a href="<%=APP_VROOT%>/login.asp">Inicia sesion</a></p>
    </div>
</body>
</html>

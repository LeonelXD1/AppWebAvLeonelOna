<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  login.asp - Inicio de sesion
' =====================================================================
Dim errMsg, u, p, dbFail
errMsg = ""
dbFail = (DbProbe() <> "" And InStr(DbProbe(), "ERROR") = 1)

If IsAuthenticated() Then Response.Redirect APP_VROOT & "/home.asp"

If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    u = FormS("username", LEN_USER)
    p = FormS("password", LEN_PASS)
    If u = "" Or p = "" Then
        errMsg = "Debes indicar el usuario y la contrasena."
    ElseIf Not Authenticate(u, p) Then
        errMsg = "Usuario o contrasena incorrectos."
    Else
        FlashSet "ok", "Bienvenido, " & CurrentUsername() & ". Sesion iniciada como " & UserTypeName(CurrentUserType()) & "."
        Response.Redirect APP_VROOT & "/home.asp"
    End If
End If
%><!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <meta name="color-scheme" content="light dark">
    <title>Iniciar sesion &middot; <%=H(APP_NAME)%></title>
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
        <h1>Iniciar sesion</h1>
        <p class="auth__lead">Accede a tu catalogo de musica</p>

        <% If dbFail Then %>
            <div class="notice notice--danger">No se pudo conectar con la base de datos <b>BDD_PoliMusic</b>. Verifica el servicio de SQL Server.</div>
        <% End If %>
        <% If errMsg <> "" Then %>
            <div class="notice notice--danger"><%=H(errMsg)%></div>
        <% End If %>
        <% If LCase(QueryS("msg", 20)) = "sesion" Then %>
            <div class="notice notice--warning">Tu sesion ha finalizado. Inicia sesion nuevamente.</div>
        <% ElseIf LCase(QueryS("msg", 20)) = "registro" Then %>
            <div class="notice notice--success">Cuenta creada correctamente. Ya puedes iniciar sesion.</div>
        <% ElseIf LCase(QueryS("msg", 20)) = "salida" Then %>
            <div class="notice notice--info">Has cerrado sesion correctamente.</div>
        <% End If %>

        <form method="post" action="<%=APP_VROOT%>/login.asp" autocomplete="off">
            <%=CsrfField()%>
            <div class="field">
                <label for="username">Usuario</label>
                <input type="text" id="username" name="username" maxlength="50" required
                       value="<%=HAttr(FormS("username", LEN_USER))%>" placeholder="userAdmin">
            </div>
            <div class="field">
                <label for="password">Contrasena</label>
                <input type="password" id="password" name="password" maxlength="50" required placeholder="********">
            </div>
            <button type="submit" class="btn btn--primary btn--block btn--lg"><%=Icon("logout", 17)%><span>Entrar</span></button>
        </form>

        <p class="auth__alt">No tienes cuenta? <a href="<%=APP_VROOT%>/register.asp">Registrate</a></p>

        <div class="hintbox">
            <b>Cuentas de prueba (datos iniciales)</b><br>
            Administrador: <code>userAdmin</code> / <code>12345678</code><br>
            Usuario estandar: <code>LeonelOna</code> / <code>123456789</code>
        </div>
    </div>
</body>
</html>

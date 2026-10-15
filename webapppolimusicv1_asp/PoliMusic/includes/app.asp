<!--#include file="config.asp"-->
<!--#include file="db.asp"-->
<!--#include file="functions.asp"-->
<!--#include file="queries.asp"-->
<!--#include file="ui.asp"-->
<!--#include file="security.asp"-->
<%
' =====================================================================
'  PoliMusic - includes/app.asp
'  Arranque comun: incluye la infraestructura y fija cabeceras.
'  Debe incluirse como PRIMERA instruccion de cada pagina.
' =====================================================================

Response.Buffer = True
Response.CodePage = 65001
Response.CharSet = "utf-8"
Session.CodePage = 65001
Session.Timeout = SESSION_TIMEOUT_MIN

' Cabeceras defensivas basicas
Response.AddHeader "X-Content-Type-Options", "nosniff"
Response.AddHeader "X-Frame-Options", "SAMEORIGIN"
Response.AddHeader "Referrer-Policy", "same-origin"
Response.AddHeader "Cache-Control", "no-store, no-cache, must-revalidate"

' Si no hay token de sesion todavia, se crea (necesario para CSRF).
If Len(CStr(Session("csrf_token") & "")) = 0 Then Session("csrf_token") = NewToken()
%>

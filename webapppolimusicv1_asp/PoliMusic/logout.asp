<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  logout.asp - Cierre de sesion (destruye la sesion y su cookie)
' =====================================================================
DoLogout()
Response.Redirect APP_VROOT & "/login.asp?msg=salida"
%>

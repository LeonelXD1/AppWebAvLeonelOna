<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' Punto de entrada: enruta segun el estado de la sesion.
If IsAuthenticated() Then
    Response.Redirect APP_VROOT & "/home.asp"
Else
    Response.Redirect APP_VROOT & "/login.asp"
End If
%>

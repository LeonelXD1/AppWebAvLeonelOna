<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  play.asp - Endpoint de registro de reproducciones.
'  Recibe POST id + csrf desde el reproductor y suma 1 a TBL_SONG.PLAYS.
' =====================================================================
Response.ContentType = "text/plain"
Response.CharSet = "utf-8"

Dim songId, p
songId = FormInt("id", 0)

If Not IsAuthenticated() Then
    Response.Status = "401 Unauthorized"
    Response.Write "auth"
    Response.End
End If

If Not CsrfValid() Then
    Response.Status = "403 Forbidden"
    Response.Write "csrf"
    Response.End
End If

If songId <= 0 Then
    Response.Status = "400 Bad Request"
    Response.Write "bad-request"
    Response.End
End If

Set p = New DbParams
p.Add "@id", adInteger, 0, songId

If DbExec("UPDATE TBL_SONG SET PLAYS = ISNULL(PLAYS, 0) + 1 WHERE ID_SONG = @id", p) Then
    Response.Write "ok"
Else
    Response.Status = "500 Internal Server Error"
    Response.Write "error"
End If
%>

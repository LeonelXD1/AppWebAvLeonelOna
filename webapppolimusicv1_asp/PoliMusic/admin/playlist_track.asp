<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include virtual="/PoliMusic/includes/app.asp"-->
<%
' =====================================================================
'  admin/playlist_track.asp - Anadir / quitar canciones de una playlist
'  (TBL_PLAYLIST_SONG) desde el panel de administracion.
' =====================================================================
RequireAdmin()

Dim plId, songId, action, p
plId   = 0
songId = 0
action = ""

If UCase(Request.ServerVariables("REQUEST_METHOD")) <> "POST" Then
    Response.Redirect APP_VROOT & "/admin/playlists.asp"
End If

CsrfCheck()
action = FormS("action", 20)
plId   = FormInt("playlist_id", 0)
songId = FormInt("song_id", 0)

If plId <= 0 Or songId <= 0 Then
    FlashSet "error", "Datos incompletos para modificar la playlist."
    Response.Redirect APP_VROOT & "/admin/playlists.asp"
End If

If action = "add" Then
    Set p = New DbParams
    p.Add "@pl", adInteger, 0, plId
    p.Add "@sg", adInteger, 0, songId
    If DbExec("INSERT INTO TBL_PLAYLIST_SONG (ID_PLAYLIST, ID_SONG) " & _
              "SELECT @pl, @sg WHERE NOT EXISTS (SELECT 1 FROM TBL_PLAYLIST_SONG " & _
              "WHERE ID_PLAYLIST = @pl AND ID_SONG = @sg)", p) Then
        FlashSet "ok", "Cancion anadida a la playlist."
    Else
        FlashSet "error", "No se pudo anadir la cancion: " & LastDbError
    End If
ElseIf action = "remove" Then
    Set p = New DbParams
    p.Add "@pl", adInteger, 0, plId
    p.Add "@sg", adInteger, 0, songId
    If DbExec("DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = @pl AND ID_SONG = @sg", p) Then
        FlashSet "ok", "Cancion quitada de la playlist."
    Else
        FlashSet "error", "No se pudo quitar la cancion: " & LastDbError
    End If
Else
    FlashSet "error", "Accion no reconocida."
End If

Response.Redirect APP_VROOT & "/admin/playlist_edit.asp?id=" & plId
%>

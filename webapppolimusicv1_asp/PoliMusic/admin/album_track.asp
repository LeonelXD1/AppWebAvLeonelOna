<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include virtual="/PoliMusic/includes/app.asp"-->
<%
' =====================================================================
'  admin/album_track.asp - Anadir / quitar canciones del tracklist
'  de un album (TBL_TRACKLIST).
' =====================================================================
RequireAdmin()

Dim albumId, songId, action, p
albumId = 0
songId  = 0
action  = ""

If UCase(Request.ServerVariables("REQUEST_METHOD")) <> "POST" Then
    Response.Redirect APP_VROOT & "/admin/albums.asp"
End If

CsrfCheck()
action  = FormS("action", 20)
albumId = FormInt("album_id", 0)
songId  = FormInt("song_id", 0)

If albumId <= 0 Or songId <= 0 Then
    FlashSet "error", "Datos incompletos para modificar el tracklist."
    Response.Redirect APP_VROOT & "/admin/albums.asp"
End If

If action = "add" Then
    Set p = New DbParams
    p.Add "@a", adInteger, 0, albumId
    p.Add "@s", adInteger, 0, songId
    If DbExec("INSERT INTO TBL_TRACKLIST (ID_ALBUM, ID_SONG) " & _
              "SELECT @a, @s WHERE NOT EXISTS (SELECT 1 FROM TBL_TRACKLIST " & _
              "WHERE ID_ALBUM = @a AND ID_SONG = @s)", p) Then
        FlashSet "ok", "Cancion anadida al album."
    Else
        FlashSet "error", "No se pudo anadir la cancion al album: " & LastDbError
    End If
ElseIf action = "remove" Then
    Set p = New DbParams
    p.Add "@a", adInteger, 0, albumId
    p.Add "@s", adInteger, 0, songId
    If DbExec("DELETE FROM TBL_TRACKLIST WHERE ID_ALBUM = @a AND ID_SONG = @s", p) Then
        FlashSet "ok", "Cancion quitada del album."
    Else
        FlashSet "error", "No se pudo quitar la cancion del album: " & LastDbError
    End If
Else
    FlashSet "error", "Accion no reconocida."
End If

Response.Redirect APP_VROOT & "/admin/album_edit.asp?id=" & albumId
%>

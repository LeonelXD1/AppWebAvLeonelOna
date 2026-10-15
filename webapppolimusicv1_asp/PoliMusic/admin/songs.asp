<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include virtual="/PoliMusic/includes/app.asp"-->
<%
' =====================================================================
'  admin/songs.asp - CRUD de canciones (listado + eliminacion)
' =====================================================================
RequireAdmin()

Dim PageTitle, ActiveNav, AdminTab
PageTitle = "Administrar canciones"
ActiveNav = "admin"
AdminTab = "songs"

' --- Eliminacion (POST) ---
If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    Dim delId, p
    delId = FormInt("id", 0)
    If FormS("action", 20) = "delete" And delId > 0 Then
        Set p = New DbParams
        p.Add "@id", adInteger, 0, delId
        ' Se limpian primero las dependencias (integridad referencial).
        DbExec "DELETE FROM TBL_TRACKLIST WHERE ID_SONG = @id", p
        DbExec "DELETE FROM TBL_PLAYER WHERE ID_SONG = @id", p
        DbExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_SONG = @id", p
        If DbExec("DELETE FROM TBL_SONG WHERE ID_SONG = @id", p) Then
            FlashSet "ok", "Cancion eliminada correctamente."
        Else
            FlashSet "error", "No se pudo eliminar la cancion: " & LastDbError
        End If
    End If
    Response.Redirect APP_VROOT & "/admin/songs.asp"
End If

Dim rs, num
%>
<!--#include virtual="/PoliMusic/includes/header.asp"-->

<div class="page-head">
    <div>
        <h1>Canciones</h1>
        <p class="sub">Alta, edicion y baja de las pistas del catalogo.</p>
    </div>
    <div>
        <a class="btn btn--primary" href="<%=APP_VROOT%>/admin/song_edit.asp">+ Nueva cancion</a>
    </div>
</div>

<!--#include file="nav.asp"-->

<%
Set rs = DbQuery(SqlSongs("", "s.SONG_NAME"), Nothing)
If rs Is Nothing Then
    Response.Write "<div class=""notice notice--danger"">No se pudo consultar el catalogo: " & H(LastDbError) & "</div>"
ElseIf rs.EOF Then
    Response.Write EmptyState("music", "Sin canciones", "Pulsa en Nueva cancion para anadir la primera.")
Else
    Response.Write "<div class=""table-wrap""><table class=""data""><thead><tr>" & _
                   "<th>#</th><th></th><th>Cancion</th><th>Artistas</th><th>Album</th>" & _
                   "<th>Reproducciones</th><th>Audio</th><th></th></tr></thead><tbody>"
    num = 0
    Do While Not rs.EOF
        num = num + 1
        Response.Write "<tr>"
        Response.Write "<td>" & num & "</td>"
        Response.Write "<td><img class=""thumb"" src=""" & HAttr(AlbumImage(rs("ALBUM_IMAGE"))) & """ alt=""""></td>"
        Response.Write "<td>" & H(rs("SONG_NAME")) & "</td>"
        Response.Write "<td>" & H(rs("ARTISTS")) & "</td>"
        Response.Write "<td>" & H(rs("ALBUM_TITLE") & "") & "</td>"
        Response.Write "<td>" & H(rs("PLAYS")) & "</td>"
        If SongUrl(rs("SONG_PATH")) = "" Then
            Response.Write "<td><span class=""tag tag--danger"">sin archivo</span></td>"
        Else
            Response.Write "<td><span class=""tag tag--accent"">ok</span></td>"
        End If
        Response.Write "<td class=""actions"">" & _
            "<a class=""btn btn--fill btn--sm"" href=""" & APP_VROOT & "/admin/song_edit.asp?id=" & rs("ID_SONG") & """>Editar</a>" & _
            MiniForm(APP_VROOT & "/admin/songs.asp", _
                     Hidden("action", "delete") & Hidden("id", rs("ID_SONG")), _
                     "Eliminar", "btn btn--danger btn--sm", "Eliminar la cancion y sus relaciones?", "trash") & _
            "</td>"
        Response.Write "</tr>"
        rs.MoveNext
    Loop
    Response.Write "</tbody></table></div>"
End If
%>

<!--#include virtual="/PoliMusic/includes/footer.asp"-->

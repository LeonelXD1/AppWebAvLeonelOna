<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include virtual="/PoliMusic/includes/app.asp"-->
<%
' =====================================================================
'  admin/playlists.asp - CRUD de playlists (listado + eliminacion)
'  El administrador gestiona las playlists de cualquier usuario.
' =====================================================================
RequireAdmin()

Dim PageTitle, ActiveNav, AdminTab
PageTitle = "Administrar playlists"
ActiveNav = "admin"
AdminTab = "playlists"

If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    Dim delId, p
    delId = FormInt("id", 0)
    If FormS("action", 20) = "delete" And delId > 0 Then
        Set p = New DbParams
        p.Add "@id", adInteger, 0, delId
        DbExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = @id", p
        If DbExec("DELETE FROM TBL_PLAYLIST WHERE ID_PLAYLIST = @id", p) Then
            FlashSet "ok", "Playlist eliminada correctamente."
        Else
            FlashSet "error", "No se pudo eliminar la playlist: " & LastDbError
        End If
    End If
    Response.Redirect APP_VROOT & "/admin/playlists.asp"
End If

Dim rs
%>
<!--#include virtual="/PoliMusic/includes/header.asp"-->

<div class="page-head">
    <div>
        <h1>Playlists</h1>
        <p class="sub">Como administrador puedes gestionar las playlists de todos los usuarios.</p>
    </div>
    <div>
        <a class="btn btn--primary" href="<%=APP_VROOT%>/admin/playlist_edit.asp">+ Nueva playlist</a>
    </div>
</div>

<!--#include file="nav.asp"-->

<%
Set rs = DbQuery("SELECT p.ID_PLAYLIST, p.TITLE, p.CREATION_DATE, p.TYPE, p.PHOTO, u.USERNAME, u.ID_USER, " & _
                 "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = p.ID_PLAYLIST) AS N " & _
                 "FROM TBL_PLAYLIST p INNER JOIN TBL_USER u ON u.ID_USER = p.ID_USER " & _
                 "ORDER BY u.USERNAME, p.TITLE", Nothing)
If rs Is Nothing Then
    Response.Write "<div class=""notice notice--danger"">No se pudieron consultar las playlists: " & H(LastDbError) & "</div>"
ElseIf rs.EOF Then
    Response.Write EmptyState("playlist", "Sin playlists", "No hay playlists registradas.")
Else
    Response.Write "<div class=""table-wrap""><table class=""data""><thead><tr>" & _
                   "<th>#</th><th></th><th>Titulo</th><th>Propietario</th><th>Visibilidad</th>" & _
                   "<th>Canciones</th><th>Creada</th><th></th></tr></thead><tbody>"
    Dim num
    num = 0
    Do While Not rs.EOF
        num = num + 1
        Response.Write "<tr>"
        Response.Write "<td>" & num & "</td>"
        Response.Write "<td><img class=""thumb"" src=""" & HAttr(PlaylistPhoto(rs("PHOTO"))) & """ alt=""""></td>"
        Response.Write "<td>" & H(rs("TITLE")) & "</td>"
        Response.Write "<td>" & H(rs("USERNAME")) & "</td>"
        Response.Write "<td><span class=""badge " & _
            IIf(CInt(rs("TYPE")) = PLAYLIST_PRIVATE, "badge-priv"">Privada", "badge-pub"">Publica") & "</span></td>"
        Response.Write "<td>" & H(rs("N")) & "</td>"
        Response.Write "<td>" & H(FmtDate(rs("CREATION_DATE"))) & "</td>"
        Response.Write "<td class=""actions"">" & _
            "<a class=""btn btn--fill btn--sm"" href=""" & APP_VROOT & "/playlist.asp?id=" & rs("ID_PLAYLIST") & """>Ver</a>" & _
            "<a class=""btn btn--fill btn--sm"" href=""" & APP_VROOT & "/admin/playlist_edit.asp?id=" & rs("ID_PLAYLIST") & """>Editar</a>" & _
            MiniForm(APP_VROOT & "/admin/playlists.asp", _
                     Hidden("action", "delete") & Hidden("id", rs("ID_PLAYLIST")), _
                     "Eliminar", "btn btn--danger btn--sm", "Eliminar la playlist y sus canciones?", "trash") & _
            "</td></tr>"
        rs.MoveNext
    Loop
    Response.Write "</tbody></table></div>"
End If
%>

<!--#include virtual="/PoliMusic/includes/footer.asp"-->

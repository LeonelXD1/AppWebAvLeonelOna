<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include virtual="/PoliMusic/includes/app.asp"-->
<%
' =====================================================================
'  admin/albums.asp - CRUD de albumes (listado + eliminacion)
' =====================================================================
RequireAdmin()

Dim PageTitle, ActiveNav, AdminTab
PageTitle = "Administrar albumes"
ActiveNav = "admin"
AdminTab = "albums"

If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    Dim delId, p
    delId = FormInt("id", 0)
    If FormS("action", 20) = "delete" And delId > 0 Then
        Set p = New DbParams
        p.Add "@id", adInteger, 0, delId
        DbExec "DELETE FROM TBL_TRACKLIST WHERE ID_ALBUM = @id", p
        If DbExec("DELETE FROM TBL_ALBUM WHERE ID_ALBUM = @id", p) Then
            FlashSet "ok", "Album eliminado correctamente."
        Else
            FlashSet "error", "No se pudo eliminar el album: " & LastDbError
        End If
    End If
    Response.Redirect APP_VROOT & "/admin/albums.asp"
End If

Dim rs
%>
<!--#include virtual="/PoliMusic/includes/header.asp"-->

<div class="page-head">
    <div>
        <h1>Albumes</h1>
        <p class="sub">Agrupaciones de pistas del catalogo.</p>
    </div>
    <div>
        <a class="btn btn--primary" href="<%=APP_VROOT%>/admin/album_edit.asp">+ Nuevo album</a>
    </div>
</div>

<!--#include file="nav.asp"-->

<%
Set rs = DbQuery("SELECT a.ID_ALBUM, a.TITLE_ALBUM, a.RELEASE_YEAR, a.ALBUM_IMAGE_PATH, " & _
                 "(SELECT COUNT(*) FROM TBL_TRACKLIST t WHERE t.ID_ALBUM = a.ID_ALBUM) AS N " & _
                 "FROM TBL_ALBUM a ORDER BY a.TITLE_ALBUM", Nothing)
If rs Is Nothing Then
    Response.Write "<div class=""notice notice--danger"">No se pudo consultar los albumes: " & H(LastDbError) & "</div>"
ElseIf rs.EOF Then
    Response.Write EmptyState("album", "Sin albumes", "Pulsa en Nuevo album para registrar el primero.")
Else
    Response.Write "<div class=""table-wrap""><table class=""data""><thead><tr>" & _
                   "<th>#</th><th></th><th>Titulo</th><th>Año</th><th>Canciones</th><th></th>" & _
                   "</tr></thead><tbody>"
    Dim num
    num = 0
    Do While Not rs.EOF
        num = num + 1
        Response.Write "<tr>"
        Response.Write "<td>" & num & "</td>"
        Response.Write "<td><img class=""thumb"" src=""" & HAttr(AlbumImage(rs("ALBUM_IMAGE_PATH"))) & """ alt=""""></td>"
        Response.Write "<td>" & H(rs("TITLE_ALBUM")) & "</td>"
        Response.Write "<td>" & H(rs("RELEASE_YEAR")) & "</td>"
        Response.Write "<td>" & H(rs("N")) & "</td>"
        Response.Write "<td class=""actions"">" & _
            "<a class=""btn btn--fill btn--sm"" href=""" & APP_VROOT & "/album.asp?id=" & rs("ID_ALBUM") & """>Ver</a>" & _
            "<a class=""btn btn--fill btn--sm"" href=""" & APP_VROOT & "/admin/album_edit.asp?id=" & rs("ID_ALBUM") & """>Editar</a>" & _
            MiniForm(APP_VROOT & "/admin/albums.asp", _
                     Hidden("action", "delete") & Hidden("id", rs("ID_ALBUM")), _
                     "Eliminar", "btn btn--danger btn--sm", "Eliminar el album y su tracklist?", "trash") & _
            "</td></tr>"
        rs.MoveNext
    Loop
    Response.Write "</tbody></table></div>"
End If
%>

<!--#include virtual="/PoliMusic/includes/footer.asp"-->

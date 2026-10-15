<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include virtual="/PoliMusic/includes/app.asp"-->
<%
' =====================================================================
'  admin/artists.asp - CRUD de artistas (listado + eliminacion)
' =====================================================================
RequireAdmin()

Dim PageTitle, ActiveNav, AdminTab
PageTitle = "Administrar artistas"
ActiveNav = "admin"
AdminTab = "artists"

If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    Dim delId, p
    delId = FormInt("id", 0)
    If FormS("action", 20) = "delete" And delId > 0 Then
        Set p = New DbParams
        p.Add "@id", adInteger, 0, delId
        DbExec "DELETE FROM TBL_PLAYER WHERE ID_ARTIST = @id", p
        If DbExec("DELETE FROM TBL_ARTIST WHERE ID_ARTIST = @id", p) Then
            FlashSet "ok", "Artista eliminado correctamente."
        Else
            FlashSet "error", "No se pudo eliminar el artista: " & LastDbError
        End If
    End If
    Response.Redirect APP_VROOT & "/admin/artists.asp"
End If

Dim rs
%>
<!--#include virtual="/PoliMusic/includes/header.asp"-->

<div class="page-head">
    <div>
        <h1>Artistas</h1>
        <p class="sub">Interpretes asociados a las canciones del catalogo.</p>
    </div>
    <div>
        <a class="btn btn--primary" href="<%=APP_VROOT%>/admin/artist_edit.asp">+ Nuevo artista</a>
    </div>
</div>

<!--#include file="nav.asp"-->

<%
Set rs = DbQuery("SELECT a.ID_ARTIST, a.ARTIST_NAME, a.ARTIST_LASTNAME, a.ARTIST_IMAGE, " & _
                 "(SELECT COUNT(*) FROM TBL_PLAYER p WHERE p.ID_ARTIST = a.ID_ARTIST) AS N " & _
                 "FROM TBL_ARTIST a ORDER BY a.ARTIST_NAME, a.ARTIST_LASTNAME", Nothing)
If rs Is Nothing Then
    Response.Write "<div class=""notice notice--danger"">No se pudo consultar los artistas: " & H(LastDbError) & "</div>"
ElseIf rs.EOF Then
    Response.Write EmptyState("artist", "Sin artistas", "Pulsa en Nuevo artista para registrar el primero.")
Else
    Response.Write "<div class=""table-wrap""><table class=""data""><thead><tr>" & _
                   "<th>#</th><th></th><th>Nombre</th><th>Canciones</th><th>Imagen</th><th></th>" & _
                   "</tr></thead><tbody>"
    Dim num
    num = 0
    Do While Not rs.EOF
        num = num + 1
        Response.Write "<tr>"
        Response.Write "<td>" & num & "</td>"
        Response.Write "<td><img class=""thumb thumb--round"" src=""" & HAttr(ArtistImage(rs("ARTIST_IMAGE"))) & """ alt=""""></td>"
        Response.Write "<td>" & H(Trim(rs("ARTIST_NAME") & " " & rs("ARTIST_LASTNAME") & "")) & "</td>"
        Response.Write "<td>" & H(rs("N")) & "</td>"
        Response.Write "<td style=""font-size:12px;color:var(--muted-2)"">" & H(rs("ARTIST_IMAGE") & "") & "</td>"
        Response.Write "<td class=""actions"">" & _
            "<a class=""btn btn--fill btn--sm"" href=""" & APP_VROOT & "/admin/artist_edit.asp?id=" & rs("ID_ARTIST") & """>Editar</a>" & _
            MiniForm(APP_VROOT & "/admin/artists.asp", _
                     Hidden("action", "delete") & Hidden("id", rs("ID_ARTIST")), _
                     "Eliminar", "btn btn--danger btn--sm", "Eliminar el artista y sus relaciones con canciones?", "trash") & _
            "</td></tr>"
        rs.MoveNext
    Loop
    Response.Write "</tbody></table></div>"
End If
%>

<!--#include virtual="/PoliMusic/includes/footer.asp"-->

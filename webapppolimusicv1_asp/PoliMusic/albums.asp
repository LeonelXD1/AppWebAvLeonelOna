<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  albums.asp - Catalogo de albumes
' =====================================================================
RequireLogin()

Dim PageTitle, ActiveNav
PageTitle = "Albumes"
ActiveNav = "albums"

Dim rs
%>
<!--#include file="includes/header.asp"-->

<div class="page-head">
    <div>
        <h1>Albumes</h1>
        <p class="sub">Explora el catalogo por album.</p>
    </div>
</div>

<%
Set rs = DbQuery("SELECT ID_ALBUM, TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH " & _
                 "FROM TBL_ALBUM ORDER BY TITLE_ALBUM", Nothing)
If rs Is Nothing Or rs.EOF Then
    Response.Write EmptyState("album", "Sin albumes", "No hay albumes registrados en el catalogo.")
Else
    Response.Write "<div class=""grid"">"
    Do While Not rs.EOF
        Response.Write CardAlbum(rs("ID_ALBUM"), rs("TITLE_ALBUM"), rs("RELEASE_YEAR"), rs("ALBUM_IMAGE_PATH"))
        rs.MoveNext
    Loop
    Response.Write "</div>"
End If
%>

<!--#include file="includes/footer.asp"-->

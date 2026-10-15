<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include file="includes/app.asp"-->
<%
' =====================================================================
'  artists.asp - Catalogo de artistas
' =====================================================================
RequireLogin()

Dim PageTitle, ActiveNav
PageTitle = "Artistas"
ActiveNav = "artists"

Dim rs
%>
<!--#include file="includes/header.asp"-->

<div class="page-head">
    <div>
        <h1>Artistas</h1>
        <p class="sub">Quienes interpretan las canciones del catalogo.</p>
    </div>
</div>

<%
Set rs = DbQuery("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE " & _
                 "FROM TBL_ARTIST ORDER BY ARTIST_NAME, ARTIST_LASTNAME", Nothing)
If rs Is Nothing Or rs.EOF Then
    Response.Write EmptyState("artist", "Sin artistas", "No hay artistas registrados en el catalogo.")
Else
    Response.Write "<div class=""grid"">"
    Do While Not rs.EOF
        Response.Write CardArtist(rs("ID_ARTIST"), Trim(rs("ARTIST_NAME") & " " & rs("ARTIST_LASTNAME") & ""), rs("ARTIST_IMAGE"))
        rs.MoveNext
    Loop
    Response.Write "</div>"
End If
%>

<!--#include file="includes/footer.asp"-->

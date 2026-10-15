<%
' =====================================================================
'  admin/nav.asp - Control segmentado del panel de administracion
'  La pagina debe asignar AdminTab antes de incluir este archivo.
'
'  Se usa un control segmentado (el patron del sistema para cambiar de
'  vista dentro de un mismo contexto): el indicador es un elemento
'  aparte que se coloca con un muelle desde app.js, de modo que el
'  cambio de seccion se lee como un objeto que se desplaza, no como un
'  simple cambio de color de fondo.
' =====================================================================
If IsEmpty(AdminTab) Or IsNull(AdminTab) Then AdminTab = ""

Function ATab(key)
    If LCase(CStr(AdminTab)) = LCase(key) Then
        ATab = "is-selected"
    Else
        ATab = ""
    End If
End Function
%>
<nav class="segmented" role="tablist" aria-label="Secciones del panel de administracion">
    <span class="segmented__thumb" aria-hidden="true"></span>
    <a role="tab" class="<%=ATab("index")%>"     href="<%=APP_VROOT%>/admin/index.asp">Resumen</a>
    <a role="tab" class="<%=ATab("songs")%>"     href="<%=APP_VROOT%>/admin/songs.asp">Canciones</a>
    <a role="tab" class="<%=ATab("albums")%>"    href="<%=APP_VROOT%>/admin/albums.asp">Albumes</a>
    <a role="tab" class="<%=ATab("artists")%>"   href="<%=APP_VROOT%>/admin/artists.asp">Artistas</a>
    <a role="tab" class="<%=ATab("playlists")%>" href="<%=APP_VROOT%>/admin/playlists.asp">Playlists</a>
    <a role="tab" class="<%=ATab("users")%>"     href="<%=APP_VROOT%>/admin/users.asp">Usuarios</a>
    <a role="tab" class="<%=ATab("diag")%>"      href="<%=APP_VROOT%>/admin/diagnostico.asp">Diagnostico</a>
</nav>

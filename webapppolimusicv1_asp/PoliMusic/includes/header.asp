<%
' =====================================================================
'  PoliMusic - includes/header.asp
'  Cabecera comun: <head>, barra lateral de navegacion y apertura del
'  area principal. La pagina debe definir PageTitle y ActiveNav antes.
' =====================================================================

If IsEmpty(PageTitle) Or IsNull(PageTitle) Then PageTitle = APP_NAME
If IsEmpty(ActiveNav) Or IsNull(ActiveNav) Then ActiveNav = ""

Dim navPlaylists, navPl
Set navPl = New DbParams
navPl.Add "@u", adInteger, 0, CurrentUserId()
navPlaylists = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE ID_USER = @u", navPl), 0)

Function NavClass(key)
    If LCase(CStr(ActiveNav)) = LCase(key) Then
        NavClass = "nav-item is-active"
    Else
        NavClass = "nav-item"
    End If
End Function

' Avisos de estado: cada uno con su icono y su tono.
Function MsgBlock()
    Dim e, m
    MsgBlock = ""
    e = LCase(QueryS("err", 20))
    m = LCase(QueryS("msg", 20))

    If e = "denegado" Then
        MsgBlock = MsgBlock & Notice("danger", "warning", "No tienes permisos para acceder a esa seccion.")
    ElseIf e = "noencontrado" Then
        MsgBlock = MsgBlock & Notice("danger", "warning", "El recurso solicitado no existe.")
    ElseIf e = "db" Then
        MsgBlock = MsgBlock & Notice("danger", "warning", "No fue posible conectar con la base de datos.")
    End If

    If m = "sesion" Then
        MsgBlock = MsgBlock & Notice("warning", "info", "Tu sesion ha finalizado. Inicia sesion nuevamente.")
    ElseIf m = "bienvenido" Then
        MsgBlock = MsgBlock & Notice("success", "check", "Sesion iniciada correctamente.")
    ElseIf m = "registro" Then
        MsgBlock = MsgBlock & Notice("success", "check", "Cuenta creada. Ya puedes iniciar sesion.")
    ElseIf m = "salida" Then
        MsgBlock = MsgBlock & Notice("info", "info", "Has cerrado sesion correctamente.")
    End If
End Function
%><!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <meta name="app-root" content="<%=APP_VROOT%>">
    <meta name="csrf" content="<%=H(CsrfToken())%>">
    <meta name="color-scheme" content="light dark">
    <title><%=H(PageTitle)%> &middot; <%=H(APP_NAME)%></title>
    <%' Se aplica el tema antes del primer pintado para evitar el destello del tema equivocado. %>
    <script>
        (function () {
            try {
                var t = localStorage.getItem("polimusic.theme");
                if (t === "light" || t === "dark") {
                    document.documentElement.setAttribute("data-theme", t);
                }
            } catch (e) { }
        })();
    </script>
    <link rel="stylesheet" href="<%=APP_VROOT%>/assets/css/style.css">
    <link rel="icon" href="<%=APP_VROOT%>/assets/img/favicon.svg" type="image/svg+xml">
</head>
<body>
<div class="app">

    <aside class="sidebar">
        <a class="brand" href="<%=APP_VROOT%>/home.asp">
            <span class="brand__mark"><%=Icon("music", 20)%></span>
            <span class="brand__text">
                <b><%=H(APP_NAME)%></b>
                <span>Biblioteca musical</span>
            </span>
        </a>

        <div class="sidebar__scroll">
            <nav class="nav-group">
                <div class="nav-group__title">Explorar</div>
                <a class="<%=NavClass("home")%>" href="<%=APP_VROOT%>/home.asp"><%=Icon("home", 19)%><span>Inicio</span></a>
                <a class="<%=NavClass("search")%>" href="<%=APP_VROOT%>/search.asp"><%=Icon("search", 19)%><span>Buscar</span></a>
                <a class="<%=NavClass("songs")%>" href="<%=APP_VROOT%>/songs.asp"><%=Icon("music", 19)%><span>Canciones</span></a>
                <a class="<%=NavClass("albums")%>" href="<%=APP_VROOT%>/albums.asp"><%=Icon("album", 19)%><span>Albumes</span></a>
                <a class="<%=NavClass("artists")%>" href="<%=APP_VROOT%>/artists.asp"><%=Icon("artist", 19)%><span>Artistas</span></a>
            </nav>

            <nav class="nav-group">
                <div class="nav-group__title">Mi biblioteca</div>
                <a class="<%=NavClass("playlists")%>" href="<%=APP_VROOT%>/playlists.asp">
                    <%=Icon("playlist", 19)%><span>Playlists</span>
                    <span class="nav-item__count"><%=navPlaylists%></span>
                </a>
                <a class="<%=NavClass("profile")%>" href="<%=APP_VROOT%>/profile.asp"><%=Icon("profile", 19)%><span>Mi perfil</span></a>
            </nav>

            <% If IsAdmin() Then %>
            <nav class="nav-group">
                <div class="nav-group__title">Administracion</div>
                <a class="<%=NavClass("admin")%>" href="<%=APP_VROOT%>/admin/index.asp"><%=Icon("panel", 19)%><span>Panel de control</span></a>
            </nav>
            <% End If %>
        </div>

        <div class="sidebar__foot">
            <div class="user-chip">
                <img src="<%=H(UserPhoto(CurrentUserPhoto()))%>" alt="">
                <div class="grow">
                    <div class="user-chip__name"><%=H(CurrentUsername())%></div>
                    <div class="user-chip__role"><%=H(UserTypeName(CurrentUserType()))%></div>
                </div>
            </div>
            <a class="btn btn--fill btn--block mt-4" href="<%=APP_VROOT%>/logout.asp"><%=Icon("logout", 17)%><span>Cerrar sesion</span></a>
        </div>
    </aside>

    <main class="main">
        <div class="topbar">
            <div class="topbar__inner">
                <form class="search" action="<%=APP_VROOT%>/search.asp" method="get" role="search">
                    <%=Icon("search", 17)%>
                    <input type="search" name="q" placeholder="Buscar canciones, albumes o artistas"
                           value="<%=HAttr(QueryS("q", 80))%>" autocomplete="off" aria-label="Buscar">
                </form>
                <div class="topbar__actions">
                    <button type="button" class="btn btn--fill btn--icon" data-theme-toggle aria-label="Cambiar apariencia"></button>
                    <% If IsAdmin() Then %>
                        <a class="btn btn--tinted" href="<%=APP_VROOT%>/admin/index.asp"><%=Icon("panel", 17)%><span>Panel admin</span></a>
                    <% End If %>
                </div>
            </div>
        </div>

        <div class="main__inner">
            <%=MsgBlock()%>
            <%=FlashRender()%>

<%
' =====================================================================
'  PoliMusic - includes/ui.asp
'  Sistema de componentes de interfaz.
'
'  Incluye un set de iconos SVG dibujados sobre una rejilla de 24x24 con
'  trazo uniforme de 1.7 px, trazos redondeados y sin relleno: el mismo
'  lenguaje que usan los simbolos del sistema, de modo que todos los
'  iconos pesan visualmente lo mismo.
'
'  NOTA: VBScript no distingue mayusculas, por lo que ninguna variable
'  local puede llamarse igual que una funcion global (H, S, ...).
'  Aqui se usa siempre "buf" como acumulador de HTML.
' =====================================================================

' ---------------------------------------------------------------------
'  Icon: devuelve un icono SVG en linea.
'  Se usan comillas simples en los atributos SVG para no tener que
'  escapar las dobles dentro de las cadenas de VBScript.
' ---------------------------------------------------------------------
Function Icon(name, size)
    Dim sz, key, body
    sz = 24
    If size > 0 Then sz = size
    key = LCase(Trim(name & ""))
    body = ""

    Select Case key
        Case "home"
            body = "<path d='M3.7 10.7 12 4.2l8.3 6.5'/><path d='M6.2 9.9v9.6h11.6V9.9'/>"
        Case "search"
            body = "<circle cx='11' cy='11' r='6.3'/><path d='M15.7 15.7 20 20'/>"
        Case "music"
            body = "<path d='M9 18V6.5l9-2V16.5'/><circle cx='6.6' cy='18' r='2.4'/><circle cx='15.6' cy='16.5' r='2.4'/>"
        Case "album"
            body = "<circle cx='12' cy='12' r='8.3'/><circle cx='12' cy='12' r='2.4'/>"
        Case "artist"
            body = "<rect x='9.2' y='3.2' width='5.6' height='10.4' rx='2.8'/>" & _
                   "<path d='M5.6 11.4a6.4 6.4 0 0 0 12.8 0'/><path d='M12 17.8v2.8'/>"
        Case "playlist"
            body = "<path d='M4.4 7.4h9'/><path d='M4.4 12h9'/><path d='M4.4 16.6h5.4'/>" & _
                   "<path d='M16.2 10.4 20.4 13l-4.2 2.6z' fill='currentColor' stroke='none'/>"
        Case "profile"
            body = "<circle cx='12' cy='8.4' r='3.7'/>" & _
                   "<path d='M4.9 20c.9-3.7 3.7-5.9 7.1-5.9s6.2 2.2 7.1 5.9'/>"
        Case "panel"
            body = "<rect x='4' y='4' width='6.6' height='6.6' rx='2'/>" & _
                   "<rect x='13.4' y='4' width='6.6' height='6.6' rx='2'/>" & _
                   "<rect x='4' y='13.4' width='6.6' height='6.6' rx='2'/>" & _
                   "<rect x='13.4' y='13.4' width='6.6' height='6.6' rx='2'/>"
        Case "logout"
            body = "<path d='M15 5.4h2.9A1.6 1.6 0 0 1 19.5 7v10a1.6 1.6 0 0 1-1.6 1.6H15'/>" & _
                   "<path d='M11 8.5 14.5 12 11 15.5'/><path d='M4.6 12h9.9'/>"
        Case "play"
            body = "<path d='M8.2 5.6v12.8L18.8 12z' fill='currentColor' stroke='none'/>"
        Case "pause"
            body = "<rect x='8.5' y='5.6' width='2.7' height='12.8' rx='1.2' fill='currentColor' stroke='none'/>" & _
                   "<rect x='12.8' y='5.6' width='2.7' height='12.8' rx='1.2' fill='currentColor' stroke='none'/>"
        Case "prev"
            body = "<path d='M6.6 6.4v11.2'/><path d='M18.4 6.6v10.8L9.8 12z' fill='currentColor' stroke='none'/>"
        Case "next"
            body = "<path d='M17.4 6.4v11.2'/><path d='M5.6 6.6v10.8L14.2 12z' fill='currentColor' stroke='none'/>"
        Case "volume"
            body = "<path d='M4.4 9.4h3.2L11.8 5.6v12.8L7.6 14.6H4.4z'/>" & _
                   "<path d='M15.3 9.7a3.4 3.4 0 0 1 0 4.6'/><path d='M18 7.3a7 7 0 0 1 0 9.4'/>"
        Case "mute"
            body = "<path d='M4.4 9.4h3.2L11.8 5.6v12.8L7.6 14.6H4.4z'/>" & _
                   "<path d='M15.4 10.2 19.6 14'/><path d='M19.6 10.2 15.4 14'/>"
        Case "plus"
            body = "<path d='M12 5.7v12.6'/><path d='M5.7 12h12.6'/>"
        Case "minus"
            body = "<path d='M5.7 12h12.6'/>"
        Case "pencil"
            body = "<path d='M4.6 19.4l.8-3.8 9.5-9.5a2.1 2.1 0 0 1 3 3l-9.5 9.5z'/>" & _
                   "<path d='M13.4 7.1l3 3'/>"
        Case "trash"
            body = "<path d='M4.6 7.4h14.8'/><path d='M9.4 7.4V5.2h5.2v2.2'/>" & _
                   "<path d='M6.7 7.4l.8 10.8a1.6 1.6 0 0 0 1.6 1.5h5.8a1.6 1.6 0 0 0 1.6-1.5l.8-10.8'/>"
        Case "eye"
            body = "<path d='M2.7 12S6.3 6 12 6s9.3 6 9.3 6-3.6 6-9.3 6-9.3-6-9.3-6z'/>" & _
                   "<circle cx='12' cy='12' r='2.9'/>"
        Case "check"
            body = "<path d='M5.2 12.6l4.5 4.5L18.8 7'/>"
        Case "close"
            body = "<path d='M6.4 6.4 17.6 17.6'/><path d='M17.6 6.4 6.4 17.6'/>"
        Case "chevron-left"
            body = "<path d='M14.6 5.6 8.2 12l6.4 6.4'/>"
        Case "chevron-right"
            body = "<path d='M9.4 5.6 15.8 12l-6.4 6.4'/>"
        Case "sun"
            body = "<circle cx='12' cy='12' r='4'/>" & _
                   "<path d='M12 2.6v2.2M12 19.2v2.2M2.6 12h2.2M19.2 12h2.2'/>" & _
                   "<path d='M5.5 5.5 7.1 7.1M16.9 16.9l1.6 1.6M18.5 5.5 16.9 7.1M7.1 16.9l-1.6 1.6'/>"
        Case "moon"
            body = "<path d='M20.2 14.7A8.7 8.7 0 0 1 9.3 3.8a8.8 8.8 0 1 0 10.9 10.9z'/>"
        Case "users"
            body = "<circle cx='9.4' cy='8.6' r='3.3'/>" & _
                   "<path d='M3.4 19.6c.8-3.3 3.2-5.2 6-5.2s5.2 1.9 6 5.2'/>" & _
                   "<path d='M16.4 6.3a3.3 3.3 0 0 1 0 6.2'/><path d='M17.9 14.8c1.8.6 3 2.2 3.4 4.3'/>"
        Case "activity"
            body = "<path d='M3.4 12.6h3.9l2.6-6.2 3.6 11.2 2.5-5h4.6'/>"
        Case "globe"
            body = "<circle cx='12' cy='12' r='8.3'/><path d='M3.7 12h16.6'/>" & _
                   "<path d='M12 3.7c2.2 2.4 3.3 5.2 3.3 8.3s-1.1 5.9-3.3 8.3c-2.2-2.4-3.3-5.2-3.3-8.3s1.1-5.9 3.3-8.3z'/>"
        Case "lock"
            body = "<path d='M7.4 10.6V8.2a4.6 4.6 0 0 1 9.2 0v2.4'/>" & _
                   "<rect x='5.2' y='10.6' width='13.6' height='9.4' rx='2.6'/>"
        Case "heart"
            body = "<path d='M12 19.6C9.4 17.8 4.4 14.4 4.4 10.6A4.1 4.1 0 0 1 12 8a4.1 4.1 0 0 1 7.6 2.6c0 3.8-5 7.2-7.6 9z'/>"
        Case "sparkle"
            body = "<path d='M12 3.6l1.9 5.3 5.3 1.9-5.3 1.9L12 18l-1.9-5.3L4.8 10.8l5.3-1.9z'/>"
        Case "queue"
            body = "<path d='M4.4 7.4h11'/><path d='M4.4 12h11'/><path d='M4.4 16.6h7'/>" & _
                   "<path d='M18 9.6v8.2'/><circle cx='16.2' cy='18' r='1.9'/>"
        Case "info"
            body = "<circle cx='12' cy='12' r='8.3'/><path d='M12 11v5.2'/><path d='M12 7.9v.1'/>"
        Case "warning"
            body = "<path d='M12 4.2 21 19.4H3z'/><path d='M12 9.6v4.6'/><path d='M12 16.9v.1'/>"
        Case Else
            body = "<circle cx='12' cy='12' r='8.3'/>"
    End Select

    Icon = "<svg class='icon' width='" & sz & "' height='" & sz & "' viewBox='0 0 24 24' " & _
           "fill='none' stroke='currentColor' stroke-width='1.7' stroke-linecap='round' " & _
           "stroke-linejoin='round' aria-hidden='true' focusable='false'>" & body & "</svg>"
End Function

' ---------------------------------------------------------------------
'  Helpers de formularios
' ---------------------------------------------------------------------
Function Hidden(name, value)
    Hidden = "<input type=""hidden"" name=""" & HAttr(name) & """ value=""" & HAttr(value) & """>"
End Function

' Formulario POST minimo (lleva el token CSRF) con boton.
' iconName es opcional: si se indica, el boton muestra el icono.
Function MiniForm(action, fields, label, cssClass, confirmText, iconName)
    Dim buf, glyph
    glyph = ""
    If Len(iconName & "") > 0 Then glyph = Icon(iconName, 17)

    buf = "<form class=""inline-form"" method=""post"" action=""" & HAttr(action) & """"
    If confirmText <> "" Then
        buf = buf & " onsubmit=""return confirm('" & Replace(confirmText, "'", "\'") & "');"""
    End If
    buf = buf & ">" & CsrfField() & fields & _
        "<button type=""submit"" class=""" & HAttr(cssClass) & """>" & glyph & "<span>" & H(label) & "</span></button></form>"
    MiniForm = buf
End Function

' Boton de enlace con icono opcional.
Function LinkButton(href, label, cssClass, iconName, title)
    Dim glyph, attr
    glyph = ""
    If Len(iconName & "") > 0 Then glyph = Icon(iconName, 17)
    attr = ""
    If Len(title & "") > 0 Then attr = " title=""" & HAttr(title) & """"
    LinkButton = "<a class=""" & HAttr(cssClass) & """ href=""" & HAttr(href) & """" & attr & ">" & _
                 glyph & "<span>" & H(label) & "</span></a>"
End Function

' ---------------------------------------------------------------------
'  SongRow: fila de la lista de canciones.
'   * el indice se transforma en ecualizador mientras suena la pista
'   * artPath    -> ruta logica de la caratula (puede ser vacia)
'   * actionHtml -> botones ya construidos para la ultima columna
' ---------------------------------------------------------------------
Function SongRow(idSong, songName, songPath, artists, artPath, plays, num, actionHtml)
    Dim url, cover, buf
    url = SongUrl(songPath)
    cover = AlbumImage(artPath)

    buf = "<div class=""track"" data-id=""" & HAttr(idSong) & """"
    If url <> "" Then
        buf = buf & " data-play data-title=""" & HAttr(songName) & """"
        buf = buf & " data-artist=""" & HAttr(artists) & """"
        buf = buf & " data-url=""" & HAttr(url) & """"
        buf = buf & " data-cover=""" & HAttr(cover) & """"
    End If
    buf = buf & ">"

    buf = buf & "<div class=""track__index"">" & _
               "<span class=""track__num"">" & H(num) & "</span>" & _
               "<span class=""track__glyph"">" & Icon("play", 15) & "</span>" & _
               "<span class=""eq"" aria-hidden=""true""><i></i><i></i><i></i></span>" & _
               "</div>"

    buf = buf & "<img class=""track__art"" src=""" & HAttr(cover) & """ alt="""" loading=""lazy"">"

    buf = buf & "<div class=""track__main"">" & _
               "<div class=""track__title"" title=""" & HAttr(songName) & """>" & H(songName) & "</div>" & _
               "<div class=""track__artist"" title=""" & HAttr(artists) & """>" & H(artists) & "</div>" & _
               "</div>"

    buf = buf & "<div class=""track__plays"">" & H(plays) & "</div>"

    buf = buf & "<div class=""track__actions"">"
    If url = "" Then
        buf = buf & "<span class=""tag tag--muted"" title=""El archivo no esta en el servidor"">" & _
                   Icon("warning", 14) & "<span>Sin audio</span></span>"
    End If
    buf = buf & actionHtml & "</div>"

    buf = buf & "</div>"
    SongRow = buf
End Function

' Cabecera de la lista de pistas.
Function TrackHead()
    TrackHead = "<div class=""track track--head"">" & _
        "<div class=""track__index"">#</div><div></div>" & _
        "<div>Titulo</div><div class=""track__plays"">Reproducciones</div><div></div></div>"
End Function

' ---------------------------------------------------------------------
'  Tarjetas del catalogo.
' ---------------------------------------------------------------------
Function CardAlbum(idAlbum, title, year, imgPath)
    Dim buf, cover
    cover = AlbumImage(imgPath)
    buf = "<article class=""card"" data-tilt>" & _
        "<a class=""card__art"" href=""" & APP_VROOT & "/album.asp?id=" & idAlbum & """>" & _
        "<img src=""" & HAttr(cover) & """ alt="""" loading=""lazy""></a>" & _
        "<div class=""card__body"">" & _
        "<a class=""card__title"" href=""" & APP_VROOT & "/album.asp?id=" & idAlbum & """>" & H(title) & "</a>" & _
        "<div class=""card__meta"">Album &middot; " & H(year) & "</div>" & _
        "</div></article>"
    CardAlbum = buf
End Function

Function CardArtist(idArtist, name, imgPath)
    Dim buf, cover
    cover = ArtistImage(imgPath)
    buf = "<article class=""card card--round"">" & _
        "<a class=""card__art"" href=""" & APP_VROOT & "/artist.asp?id=" & idArtist & """>" & _
        "<img src=""" & HAttr(cover) & """ alt="""" loading=""lazy""></a>" & _
        "<div class=""card__body card__body--center"">" & _
        "<a class=""card__title"" href=""" & APP_VROOT & "/artist.asp?id=" & idArtist & """>" & H(name) & "</a>" & _
        "<div class=""card__meta"">Artista</div>" & _
        "</div></article>"
    CardArtist = buf
End Function

Function CardPlaylist(idPlaylist, title, owner, typeName, imgPath)
    Dim buf, cover
    cover = PlaylistPhoto(imgPath)
    buf = "<article class=""card"">" & _
        "<a class=""card__art"" href=""" & APP_VROOT & "/playlist.asp?id=" & idPlaylist & """>" & _
        "<img src=""" & HAttr(cover) & """ alt="""" loading=""lazy""></a>" & _
        "<div class=""card__body"">" & _
        "<a class=""card__title"" href=""" & APP_VROOT & "/playlist.asp?id=" & idPlaylist & """>" & H(title) & "</a>" & _
        "<div class=""card__meta"">" & H(owner) & " &middot; " & H(typeName) & "</div>" & _
        "</div></article>"
    CardPlaylist = buf
End Function

' Tarjeta de cancion reproducible (pantalla principal).
Function CardSong(idSong, songName, artists, artPath, songPath)
    Dim buf, cover, url
    cover = AlbumImage(artPath)
    url = SongUrl(songPath)
    buf = "<article class=""card"""
    If url <> "" Then
        buf = buf & " data-id=""" & HAttr(idSong) & """ data-play data-title=""" & HAttr(songName) & """" & _
              " data-artist=""" & HAttr(artists) & """ data-url=""" & HAttr(url) & """ data-cover=""" & HAttr(cover) & """"
    End If
    buf = buf & ">" & _
        "<div class=""card__art""><img src=""" & HAttr(cover) & """ alt="""" loading=""lazy"">"
    If url <> "" Then
        buf = buf & "<button type=""button"" class=""card__play"" title=""Reproducir"" tabindex=""-1"">" & Icon("play", 18) & "</button>"
    End If
    buf = buf & "</div>" & _
        "<div class=""card__body"">" & _
        "<div class=""card__title"">" & H(songName) & "</div>" & _
        "<div class=""card__meta"">" & H(Clip(artists, 34)) & "</div>" & _
        "</div></article>"
    CardSong = buf
End Function

' ---------------------------------------------------------------------
'  Estado vacio reutilizable.
'  iconName solo recibe nombres del set interno, nunca datos de usuario.
' ---------------------------------------------------------------------
Function EmptyState(iconName, title, text)
    EmptyState = "<div class=""empty"">" & _
                 "<div class=""empty__icon"">" & Icon(iconName, 26) & "</div>" & _
                 "<h3 class=""empty__title"">" & H(title) & "</h3>" & _
                 "<p class=""empty__text"">" & H(text) & "</p></div>"
End Function

' ---------------------------------------------------------------------
'  Barra de titulo de seccion con enlace opcional.
' ---------------------------------------------------------------------
Function SectionHead(title, href, linkLabel)
    Dim buf
    buf = "<div class=""section-head""><h2>" & H(title) & "</h2>"
    If Len(href & "") > 0 Then
        buf = buf & "<a href=""" & HAttr(href) & """><span>" & H(linkLabel) & "</span>" & Icon("chevron-right", 15) & "</a>"
    End If
    buf = buf & "</div>"
    SectionHead = buf
End Function

' ---------------------------------------------------------------------
'  Notice: aviso de estado. Los cuatro tipos que define la guia son
'  estado, confirmacion, advertencia y error; aqui se cubren con tono
'  + icono para que se distingan tambien sin depender del color.
' ---------------------------------------------------------------------
Function Notice(kind, iconName, text)
    Notice = "<div class=""notice notice--" & HAttr(kind) & """>" & _
             Icon(iconName, 18) & "<span>" & H(text) & "</span></div>"
End Function
%>

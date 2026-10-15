<%
' =====================================================================
'  PoliMusic - includes/queries.asp
'  Fragmentos SQL reutilizables. Ningun fragmento incorpora datos de
'  usuario: los filtros se pasan siempre como parametros.
'  (Se usan variables y no Const porque VBScript no admite el operador
'   de concatenacion dentro de una declaracion Const.)
' =====================================================================

' Proyeccion de canciones con artistas concatenados, album de origen,
' artista principal y total de reproducciones. Requiere SQL Server 2017+
' por el uso de STRING_AGG.
Dim SQL_SONG_COLS, SQL_SONG_JOINS, SQL_SONG_GROUP
Dim SQL_PLAYLIST_SONGS, SQL_ALBUM_SONGS, SQL_ARTIST_SONGS

SQL_SONG_COLS = _
    "s.ID_SONG, s.SONG_NAME, s.SONG_PATH, s.PLAYS, " & _
    "ISNULL(STRING_AGG(a.ARTIST_NAME + ' ' + ISNULL(a.ARTIST_LASTNAME, ''), ', '), 'Artista desconocido') AS ARTISTS, " & _
    "(SELECT TOP 1 al.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST t " & _
    "   INNER JOIN TBL_ALBUM al ON al.ID_ALBUM = t.ID_ALBUM " & _
    "   WHERE t.ID_SONG = s.ID_SONG) AS ALBUM_IMAGE, " & _
    "(SELECT TOP 1 al.TITLE_ALBUM FROM TBL_TRACKLIST t " & _
    "   INNER JOIN TBL_ALBUM al ON al.ID_ALBUM = t.ID_ALBUM " & _
    "   WHERE t.ID_SONG = s.ID_SONG) AS ALBUM_TITLE, " & _
    "(SELECT TOP 1 a2.ID_ARTIST FROM TBL_PLAYER p2 " & _
    "   INNER JOIN TBL_ARTIST a2 ON a2.ID_ARTIST = p2.ID_ARTIST " & _
    "   WHERE p2.ID_SONG = s.ID_SONG) AS ARTIST_ID"

SQL_SONG_JOINS = _
    " FROM TBL_SONG s " & _
    " LEFT JOIN TBL_PLAYER p ON p.ID_SONG = s.ID_SONG " & _
    " LEFT JOIN TBL_ARTIST a ON a.ID_ARTIST = p.ID_ARTIST "

SQL_SONG_GROUP = _
    " GROUP BY s.ID_SONG, s.SONG_NAME, s.SONG_PATH, s.PLAYS "

' Construye la consulta de canciones. whereSql/orderSql deben ser
' fragmentos FIJOS (sin datos de usuario) o contener solo marcadores.
Function SqlSongs(whereSql, orderSql)
    Dim q
    q = "SELECT " & SQL_SONG_COLS & SQL_SONG_JOINS
    If whereSql <> "" Then q = q & " WHERE " & whereSql
    q = q & SQL_SONG_GROUP
    If orderSql <> "" Then q = q & " ORDER BY " & orderSql
    SqlSongs = q
End Function

' Canciones pertenecientes a una playlist concreta.
SQL_PLAYLIST_SONGS = _
    "SELECT " & SQL_SONG_COLS & _
    " FROM TBL_PLAYLIST_SONG ps " & _
    " INNER JOIN TBL_SONG s ON s.ID_SONG = ps.ID_SONG " & _
    " LEFT JOIN TBL_PLAYER p ON p.ID_SONG = s.ID_SONG " & _
    " LEFT JOIN TBL_ARTIST a ON a.ID_ARTIST = p.ID_ARTIST " & _
    " WHERE ps.ID_PLAYLIST = @id " & _
    SQL_SONG_GROUP & _
    " ORDER BY s.SONG_NAME"

' Canciones de un album concreto.
SQL_ALBUM_SONGS = _
    "SELECT " & SQL_SONG_COLS & _
    " FROM TBL_TRACKLIST tr " & _
    " INNER JOIN TBL_SONG s ON s.ID_SONG = tr.ID_SONG " & _
    " LEFT JOIN TBL_PLAYER p ON p.ID_SONG = s.ID_SONG " & _
    " LEFT JOIN TBL_ARTIST a ON a.ID_ARTIST = p.ID_ARTIST " & _
    " WHERE tr.ID_ALBUM = @id " & _
    SQL_SONG_GROUP & _
    " ORDER BY s.ID_SONG"

' Canciones de un artista concreto.
SQL_ARTIST_SONGS = _
    "SELECT " & SQL_SONG_COLS & _
    " FROM TBL_PLAYER pl " & _
    " INNER JOIN TBL_SONG s ON s.ID_SONG = pl.ID_SONG " & _
    " LEFT JOIN TBL_PLAYER p ON p.ID_SONG = s.ID_SONG " & _
    " LEFT JOIN TBL_ARTIST a ON a.ID_ARTIST = p.ID_ARTIST " & _
    " WHERE pl.ID_ARTIST = @id " & _
    SQL_SONG_GROUP & _
    " ORDER BY s.SONG_NAME"
%>

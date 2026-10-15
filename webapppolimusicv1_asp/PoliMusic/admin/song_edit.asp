<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include virtual="/PoliMusic/includes/app.asp"-->
<%
' =====================================================================
'  admin/song_edit.asp - Alta y edicion de canciones
'  Gestiona tambien el album (TBL_TRACKLIST) y los artistas (TBL_PLAYER)
'  asociados a la pista.
' =====================================================================
RequireAdmin()

Dim PageTitle, ActiveNav, AdminTab
ActiveNav = "admin"
AdminTab = "songs"

Dim songId, isEdit, errMsg, p, rs
Dim fName, fPath, fPlays, fAlbum, fArtists, fArtistsCsv

songId  = QueryInt("id", 0)
isEdit  = (songId > 0)
errMsg  = ""
fName   = ""
fPath   = "~/songFiles/"
fPlays  = 0
fAlbum  = 0
fArtistsCsv = ","

' --- Carga previa en edicion ---
If isEdit Then
    Set p = New DbParams
    p.Add "@id", adInteger, 0, songId
    Set rs = DbQuery("SELECT ID_SONG, SONG_NAME, SONG_PATH, PLAYS FROM TBL_SONG WHERE ID_SONG = @id", p)
    If rs Is Nothing Or rs.EOF Then
        Response.Redirect APP_VROOT & "/admin/songs.asp?err=noencontrado"
    End If
    fName  = CStr(rs("SONG_NAME") & "")
    fPath  = CStr(rs("SONG_PATH") & "")
    fPlays = ToInt(rs("PLAYS"), 0)
    rs.Close

    Set p = New DbParams
    p.Add "@id", adInteger, 0, songId
    Set rs = DbQuery("SELECT TOP 1 ID_ALBUM FROM TBL_TRACKLIST WHERE ID_SONG = @id", p)
    If Not rs.EOF Then fAlbum = ToInt(rs("ID_ALBUM"), 0)
    rs.Close

    Set p = New DbParams
    p.Add "@id", adInteger, 0, songId
    Set rs = DbQuery("SELECT ID_ARTIST FROM TBL_PLAYER WHERE ID_SONG = @id", p)
    Do While Not rs.EOF
        fArtistsCsv = fArtistsCsv & rs("ID_ARTIST") & ","
        rs.MoveNext
    Loop
    rs.Close
End If

' --- Procesar formulario ---
If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    fName  = FormS("song_name", LEN_SONG)
    fPath  = FormS("song_path", LEN_PATH)
    fPlays = FormInt("plays", 0)
    fAlbum = FormInt("album_id", 0)
    fArtistsCsv = "," & FormS("artists", 400) & ","

    If Len(fName) < 1 Then
        errMsg = "El nombre de la cancion es obligatorio."
    ElseIf Not IsValidAssetPath(fPath) Then
        errMsg = "La ruta del audio no es valida. Usa el formato ~/songFiles/archivo.mp3"
    ElseIf fPlays < 0 Then
        errMsg = "Las reproducciones no pueden ser negativas."
    Else
        Dim newId
        If isEdit Then
            Set p = New DbParams
            p.Add "@n",  adVarChar, LEN_SONG, fName
            p.Add "@pa", adVarChar, LEN_PATH, fPath
            p.Add "@pl", adInteger, 0, fPlays
            p.Add "@id", adInteger, 0, songId
            If Not DbExec("UPDATE TBL_SONG SET SONG_NAME = @n, SONG_PATH = @pa, PLAYS = @pl WHERE ID_SONG = @id", p) Then
                errMsg = "No se pudo actualizar la cancion: " & LastDbError
            Else
                newId = songId
            End If
        Else
            Set p = New DbParams
            p.Add "@n",  adVarChar, LEN_SONG, fName
            p.Add "@pa", adVarChar, LEN_PATH, fPath
            p.Add "@pl", adInteger, 0, fPlays
            newId = DbInsertReturnId("INSERT INTO TBL_SONG (SONG_NAME, SONG_PATH, PLAYS) VALUES (@n, @pa, @pl)", p)
            If newId <= 0 Then errMsg = "No se pudo crear la cancion: " & LastDbError
        End If

        If errMsg = "" And newId > 0 Then
            ' Album: se reemplaza la relacion previa.
            Set p = New DbParams
            p.Add "@id", adInteger, 0, newId
            DbExec "DELETE FROM TBL_TRACKLIST WHERE ID_SONG = @id", p
            If fAlbum > 0 Then
                Set p = New DbParams
                p.Add "@a", adInteger, 0, fAlbum
                p.Add "@s", adInteger, 0, newId
                DbExec "INSERT INTO TBL_TRACKLIST (ID_ALBUM, ID_SONG) VALUES (@a, @s)", p
            End If

            ' Artistas: se reemplaza la relacion previa.
            Set p = New DbParams
            p.Add "@id", adInteger, 0, newId
            DbExec "DELETE FROM TBL_PLAYER WHERE ID_SONG = @id", p

            Dim artList, i, artId
            artList = Split(fArtistsCsv, ",")
            For i = 0 To UBound(artList)
                artId = ToInt(Trim(artList(i)), 0)
                If artId > 0 Then
                    Set p = New DbParams
                    p.Add "@s", adInteger, 0, newId
                    p.Add "@a", adInteger, 0, artId
                    DbExec "INSERT INTO TBL_PLAYER (ID_SONG, ID_ARTIST) " & _
                           "SELECT @s, @a WHERE NOT EXISTS (SELECT 1 FROM TBL_PLAYER " & _
                           "WHERE ID_SONG = @s AND ID_ARTIST = @a)", p
                End If
            Next

            FlashSet "ok", IIf(isEdit, "Cancion actualizada correctamente.", "Cancion creada correctamente.")
            Response.Redirect APP_VROOT & "/admin/songs.asp"
        End If
    End If
End If

PageTitle = IIf(isEdit, "Editar cancion", "Nueva cancion")

Dim rsAlbums, rsArtists, fso, fld, f
Set rsAlbums  = DbQuery("SELECT ID_ALBUM, TITLE_ALBUM FROM TBL_ALBUM ORDER BY TITLE_ALBUM", Nothing)
Set rsArtists = DbQuery("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME FROM TBL_ARTIST ORDER BY ARTIST_NAME", Nothing)
%>
<!--#include virtual="/PoliMusic/includes/header.asp"-->

<div class="page-head">
    <div>
        <h1><%=H(PageTitle)%></h1>
        <p class="sub">Una cancion puede pertenecer a un album y estar interpretada por varios artistas.</p>
    </div>
    <div>
        <a class="btn btn--ghost" href="<%=APP_VROOT%>/admin/songs.asp">Volver</a>
    </div>
</div>

<!--#include file="nav.asp"-->

<div class="panel" style="max-width:860px">
    <% If errMsg <> "" Then %>
        <div class="notice notice--danger"><%=H(errMsg)%></div>
    <% End If %>

    <form method="post" action="<%=APP_VROOT%>/admin/song_edit.asp<% If isEdit Then %>?id=<%=songId%><% End If %>">
        <%=CsrfField()%>

        <div class="form-grid">
            <div class="field">
                <label for="song_name">Nombre de la cancion</label>
                <input type="text" id="song_name" name="song_name" maxlength="<%=LEN_SONG%>" required
                       value="<%=HAttr(fName)%>" placeholder="Adventure">
            </div>
            <div class="field">
                <label for="plays">Reproducciones</label>
                <input type="number" id="plays" name="plays" min="0" value="<%=HAttr(fPlays)%>">
            </div>
        </div>

        <div class="field">
            <label for="song_path">Ruta del archivo de audio</label>
            <input type="text" id="song_path" name="song_path" maxlength="<%=LEN_PATH%>" required
                   list="songfiles" value="<%=HAttr(fPath)%>" placeholder="~/songFiles/bensound-adventure.mp3">
            <datalist id="songfiles">
                <%
                Set fso = Server.CreateObject("Scripting.FileSystemObject")
                If fso.FolderExists(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/songFiles")) Then
                    Set fld = fso.GetFolder(Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/songFiles"))
                    For Each f In fld.Files
                        Response.Write "<option value=""~/songFiles/" & HAttr(f.Name) & """></option>"
                    Next
                End If
                %>
            </datalist>
            <div class="hint">Formato admitido: <code>~/songFiles/archivo.mp3</code>. Si el archivo no existe, la pista se marca como "sin audio".</div>
        </div>

        <div class="form-grid">
            <div class="field">
                <label for="album_id">Album</label>
                <select id="album_id" name="album_id">
                    <option value="0">-- Sin album --</option>
                    <%
                    If Not (rsAlbums Is Nothing) Then
                        Do While Not rsAlbums.EOF
                            Response.Write "<option value=""" & rsAlbums("ID_ALBUM") & """"
                            If ToInt(rsAlbums("ID_ALBUM"), 0) = fAlbum Then Response.Write " selected"
                            Response.Write ">" & H(rsAlbums("TITLE_ALBUM")) & "</option>"
                            rsAlbums.MoveNext
                        Loop
                    End If
                    %>
                </select>
            </div>
            <div class="field">
                <label for="artists">Artistas (seleccion multiple)</label>
                <select id="artists" name="artists" multiple size="6">
                    <%
                    If Not (rsArtists Is Nothing) Then
                        Do While Not rsArtists.EOF
                            Response.Write "<option value=""" & rsArtists("ID_ARTIST") & """"
                            If InStr(fArtistsCsv, "," & rsArtists("ID_ARTIST") & ",") > 0 Then Response.Write " selected"
                            Response.Write ">" & H(Trim(rsArtists("ARTIST_NAME") & " " & rsArtists("ARTIST_LASTNAME") & "")) & "</option>"
                            rsArtists.MoveNext
                        Loop
                    End If
                    %>
                </select>
                <div class="hint">Mantén pulsado Ctrl para elegir varios.</div>
            </div>
        </div>

        <div class="form-actions">
            <button type="submit" class="btn btn--primary"><% If isEdit Then %>Guardar cambios<% Else %>Crear cancion<% End If %></button>
            <a class="btn btn--ghost" href="<%=APP_VROOT%>/admin/songs.asp">Cancelar</a>
        </div>
    </form>
</div>

<!--#include virtual="/PoliMusic/includes/footer.asp"-->

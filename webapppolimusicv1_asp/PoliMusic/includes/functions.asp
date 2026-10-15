<%
' =====================================================================
'  PoliMusic - includes/functions.asp
'  Utilidades: saneamiento de entrada, codificacion de salida,
'  resolucion de rutas de assets y formateo.
' =====================================================================

' ---------------------------------------------------------------------
'  H: codifica una cadena para insertarla en HTML (anti-XSS).
' ---------------------------------------------------------------------
Function H(v)
    If IsNull(v) Or IsEmpty(v) Then
        H = ""
    Else
        H = Server.HTMLEncode(CStr(v))
    End If
End Function

' ---------------------------------------------------------------------
'  HAttr: igual que H pero ademas neutraliza comillas simples/dobles
'  para uso dentro de atributos HTML.
' ---------------------------------------------------------------------
Function HAttr(v)
    Dim tmp
    tmp = H(v)
    tmp = Replace(tmp, "'", "&#39;")
    HAttr = tmp
End Function

' ---------------------------------------------------------------------
'  S: saneamiento de entrada de texto.
'   - convierte Null/vacio a cadena
'   - recorta espacios
'   - elimina caracteres de control (evita inyeccion de cabeceras y
'     payloads raros en formularios)
'   - limita la longitud
' ---------------------------------------------------------------------
Function S(v, maxLen)
    Dim txt, i, ch, cp, buf
    If IsNull(v) Or IsEmpty(v) Then
        S = ""
        Exit Function
    End If
    txt = Trim(CStr(v))
    buf = ""
    For i = 1 To Len(txt)
        ch = Mid(txt, i, 1)
        cp = AscW(ch)
        If cp >= 32 And cp <> 127 Then buf = buf & ch
    Next
    If maxLen > 0 And Len(buf) > maxLen Then buf = Left(buf, maxLen)
    S = buf
End Function

' ---------------------------------------------------------------------
'  IIf: operador ternario de VBScript (evaluacion no perezosa).
' ---------------------------------------------------------------------
Function IIf(condition, ifTrue, ifFalse)
    If condition Then
        IIf = ifTrue
    Else
        IIf = ifFalse
    End If
End Function

' ---------------------------------------------------------------------
'  ToInt: conversion segura a entero con valor por defecto.
' ---------------------------------------------------------------------
Function ToInt(v, def)
    Dim n
    ToInt = def
    If IsNull(v) Or IsEmpty(v) Then Exit Function
    If Not IsNumeric(v) Then Exit Function
    n = CLng(v)
    If n > 2147483647 Or n < -2147483648 Then Exit Function
    ToInt = n
End Function

' ---------------------------------------------------------------------
'  FormS / QueryS: lecturas saneadas de Request.
' ---------------------------------------------------------------------
Function FormS(name, maxLen)
    FormS = S(Request.Form(name), maxLen)
End Function

Function QueryS(name, maxLen)
    QueryS = S(Request.QueryString(name), maxLen)
End Function

Function FormInt(name, def)
    FormInt = ToInt(Request.Form(name), def)
End Function

Function QueryInt(name, def)
    QueryInt = ToInt(Request.QueryString(name), def)
End Function

' ---------------------------------------------------------------------
'  IsValidEmail: validacion con expresion regular.
' ---------------------------------------------------------------------
Function IsValidEmail(v)
    Dim re
    IsValidEmail = False
    If Len(v) = 0 Or Len(v) > 50 Then Exit Function
    Set re = New RegExp
    re.IgnoreCase = True
    re.Pattern = "^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"
    IsValidEmail = re.Test(v)
End Function

' ---------------------------------------------------------------------
'  CanonFolder: normaliza (sin distinguir mayusculas) el nombre de la
'  carpeta de assets usada en TBL_*.PATH. Devuelve "" si es desconocida.
' ---------------------------------------------------------------------
Function CanonFolder(name)
    Dim n
    n = LCase(Trim(name & ""))
    Select Case n
        Case "songfiles"     : CanonFolder = "songFiles"
        Case "userimages"    : CanonFolder = "userImages"
        Case "playlistimages": CanonFolder = "playlistImages"
        Case "albumimages"   : CanonFolder = "albumImages"
        Case "artistimages"  : CanonFolder = "artistImages"
        Case Else            : CanonFolder = ""
    End Select
End Function

' ---------------------------------------------------------------------
'  AssetsPath: ruta FISICA de una subcarpeta de assets.
'  Se usa una ruta virtual absoluta (APP_VROOT + /assets) porque
'  Server.MapPath con una ruta relativa la resuelve respecto a la
'  carpeta de la pagina que la invoca, lo que rompe las paginas de
'  /admin/ (apuntarian a /admin/assets).
' ---------------------------------------------------------------------
Function AssetsPath(subFolder)
    If subFolder = "" Then
        AssetsPath = Server.MapPath(APP_VROOT & "/" & ASSETS_DIR)
    Else
        AssetsPath = Server.MapPath(APP_VROOT & "/" & ASSETS_DIR & "/" & subFolder)
    End If
End Function

' ---------------------------------------------------------------------
'  ResolveAsset: traduce una ruta logica almacenada en la BD
'  (p.ej. "~/songFiles/bensound-adventure.mp3") a una URL publica real.
'  Verifica la existencia fisica del archivo (sin distinguir mayusculas)
'  y devuelve fallbackUrl si no existe. Evita rutas absolutas y "..".
' ---------------------------------------------------------------------
Function ResolveAsset(dbPath, fallbackUrl)
    Dim raw, parts, folder, fileName, fso, phys, fld, f
    ResolveAsset = fallbackUrl
    If IsNull(dbPath) Or IsEmpty(dbPath) Then Exit Function
    raw = Replace(Trim(CStr(dbPath)), "\", "/")
    If raw = "" Then Exit Function
    If InStr(raw, "..") > 0 Then Exit Function          ' anti path traversal
    If Left(raw, 2) = "~/" Then raw = Mid(raw, 3)
    parts = Split(raw, "/")
    If UBound(parts) < 1 Then Exit Function
    fileName = parts(UBound(parts))
    folder = CanonFolder(parts(UBound(parts) - 1))
    If folder = "" Or fileName = "" Then Exit Function

    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    phys = AssetsPath(folder)
    If fso.FolderExists(phys) Then
        Set fld = fso.GetFolder(phys)
        For Each f In fld.Files
            If LCase(f.Name) = LCase(fileName) Then
                ResolveAsset = APP_VROOT & "/" & ASSETS_DIR & "/" & folder & "/" & f.Name
                Exit Function
            End If
        Next
    End If
End Function

' --- Envoltorios con fallback por tipo de recurso ---
Function SongUrl(p)      : SongUrl      = ResolveAsset(p, "")                                    : End Function
Function UserPhoto(p)    : UserPhoto    = ResolveAsset(p, APP_VROOT & "/assets/img/default-user.png")     : End Function
Function PlaylistPhoto(p): PlaylistPhoto = ResolveAsset(p, APP_VROOT & "/assets/img/default-playlist.png") : End Function
Function AlbumImage(p)   : AlbumImage   = ResolveAsset(p, APP_VROOT & "/assets/img/default-cover.png")    : End Function
Function ArtistImage(p)  : ArtistImage  = ResolveAsset(p, APP_VROOT & "/assets/img/default-user.png")     : End Function

' ---------------------------------------------------------------------
'  AudioAvailable: indica si la pista tiene archivo fisico reproducible.
' ---------------------------------------------------------------------
Function AudioAvailable(p)
    AudioAvailable = (SongUrl(p) <> "")
End Function

' ---------------------------------------------------------------------
'  Formateo de fechas.
' ---------------------------------------------------------------------
Function FmtDate(v)
    If IsNull(v) Or IsEmpty(v) Then
        FmtDate = "-"
    Else
        On Error Resume Next
        FmtDate = Right("0" & Day(v), 2) & "/" & Right("0" & Month(v), 2) & "/" & Year(v)
        If Err.Number <> 0 Then FmtDate = "-" : Err.Clear
        On Error GoTo 0
    End If
End Function

Function FmtDateInput(v)
    If IsNull(v) Or IsEmpty(v) Then
        FmtDateInput = ""
    Else
        On Error Resume Next
        FmtDateInput = Year(v) & "-" & Right("0" & Month(v), 2) & "-" & Right("0" & Day(v), 2)
        If Err.Number <> 0 Then FmtDateInput = "" : Err.Clear
        On Error GoTo 0
    End If
End Function

' ---------------------------------------------------------------------
'  Nombre del tipo de usuario / playlist (desde TBL_CATALOG o fallback).
' ---------------------------------------------------------------------
Function UserTypeName(t)
    If ToInt(t, 0) = USER_TYPE_ADMIN Then
        UserTypeName = "Administrador"
    Else
        UserTypeName = "Usuario"
    End If
End Function

Function PlaylistTypeName(t)
    If ToInt(t, 0) = PLAYLIST_PRIVATE Then
        PlaylistTypeName = "Privada"
    Else
        PlaylistTypeName = "Publica"
    End If
End Function

' ---------------------------------------------------------------------
'  Trunca texto para tarjetas.
' ---------------------------------------------------------------------
Function Clip(v, n)
    Dim tmp
    tmp = CStr(v & "")
    If Len(tmp) > n Then tmp = Left(tmp, n - 1) & "..."
    Clip = tmp
End Function

' ---------------------------------------------------------------------
'  IsValidUsername: solo letras, digitos, punto, guion y guion bajo.
' ---------------------------------------------------------------------
Function IsValidUsername(v)
    Dim re
    IsValidUsername = False
    If Len(v) < 3 Or Len(v) > LEN_USER Then Exit Function
    Set re = New RegExp
    re.Pattern = "^[A-Za-z0-9._\-]+$"
    IsValidUsername = re.Test(v)
End Function

' ---------------------------------------------------------------------
'  ParseIsoDate: convierte "YYYY-MM-DD" (input type=date) en fecha.
'  Devuelve Null si el valor es vacio o invalido.
' ---------------------------------------------------------------------
Function ParseIsoDate(s)
    Dim parts, y, m, d
    ParseIsoDate = Null
    s = Trim(CStr(s & ""))
    If s = "" Then Exit Function
    parts = Split(s, "-")
    If UBound(parts) <> 2 Then Exit Function
    If Not (IsNumeric(parts(0)) And IsNumeric(parts(1)) And IsNumeric(parts(2))) Then Exit Function
    y = CInt(parts(0)) : m = CInt(parts(1)) : d = CInt(parts(2))
    If y < 1900 Or y > 2100 Or m < 1 Or m > 12 Or d < 1 Or d > 31 Then Exit Function
    On Error Resume Next
    ParseIsoDate = DateSerial(y, m, d)
    If Err.Number <> 0 Then
        ParseIsoDate = Null
        Err.Clear
    End If
    On Error GoTo 0
End Function

' ---------------------------------------------------------------------
'  IsValidAssetPath: valida una ruta logica de asset escrita por el
'  administrador ("~/songFiles/x.mp3"). Debe apuntar a una carpeta
'  conocida y no puede contener ".." (anti path traversal).
' ---------------------------------------------------------------------
Function IsValidAssetPath(v)
    Dim raw, parts
    IsValidAssetPath = False
    raw = Replace(Trim(CStr(v & "")), "\", "/")
    If raw = "" Or Len(raw) > LEN_PATH Then Exit Function
    If InStr(raw, "..") > 0 Then Exit Function
    If Left(raw, 2) = "~/" Then raw = Mid(raw, 3)
    parts = Split(raw, "/")
    If UBound(parts) < 1 Then Exit Function
    If Trim(parts(UBound(parts))) = "" Then Exit Function
    IsValidAssetPath = (CanonFolder(parts(0)) <> "")
End Function

' ---------------------------------------------------------------------
'  LikePattern: construye un patron LIKE seguro a partir del termino de
'  busqueda. Neutraliza los comodines que el usuario pudiera escribir
'  (%, _ y [) para que se traten como texto literal.
' ---------------------------------------------------------------------
Function LikePattern(term)
    Dim tmp
    tmp = CStr(term & "")
    tmp = Replace(tmp, "[", "[[]")
    tmp = Replace(tmp, "%", "[%]")
    tmp = Replace(tmp, "_", "[_]")
    LikePattern = "%" & tmp & "%"
End Function

' ---------------------------------------------------------------------
'  Genera un token aleatorio (CSRF / marca de sesion).
' ---------------------------------------------------------------------
Function NewToken()
    Dim i, s, seed
    seed = Timer * 1000
    seed = seed + Len(Session.SessionID) * 7919
    Randomize seed
    s = ""
    For i = 1 To 32
        s = s & Hex(Int(Rnd() * 16))
    Next
    NewToken = s
End Function
%>

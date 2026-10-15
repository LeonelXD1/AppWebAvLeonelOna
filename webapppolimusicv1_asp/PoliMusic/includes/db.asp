<%
' =====================================================================
'  PoliMusic - includes/db.asp
'  Capa de acceso a datos. TODAS las consultas usan parametros
'  (ADODB.Command + Parameters) para neutralizar la inyeccion SQL.
' =====================================================================

' --- Constantes ADO (evitan depender de las librerias de tipos) ---
Const adCmdText          = 1
Const adParamInput       = 1
Const adInteger          = 3
Const adDate             = 7
Const adBoolean          = 11
Const adDBTimeStamp      = 135
Const adVarChar          = 200
Const adOpenStatic       = 3
Const adLockReadOnly     = 1
Const adUseClient        = 3
Const adExecuteNoRecords = 128

' Ultimo error registrado por la capa de datos (diagnostico).
Dim LastDbError
LastDbError = ""

' ---------------------------------------------------------------------
'  Clase DbParams: coleccion dinamica de parametros tipados.
' ---------------------------------------------------------------------
Class DbParams
    Private mName(), mType(), mSize(), mValue(), mCount

    Private Sub Class_Initialize()
        ReDim mName(7) : ReDim mType(7) : ReDim mSize(7) : ReDim mValue(7)
        mCount = 0
    End Sub

    Private Sub Grow()
        ReDim Preserve mName(mCount + 7)  : ReDim Preserve mType(mCount + 7)
        ReDim Preserve mSize(mCount + 7)  : ReDim Preserve mValue(mCount + 7)
    End Sub

    ' Agrega un parametro: nombre, tipo ADO, tamano (0 si no aplica), valor.
    Public Sub Add(pName, pType, pSize, pValue)
        If mCount > UBound(mName) Then Grow
        mName(mCount)  = pName
        mType(mCount)  = pType
        mSize(mCount)  = pSize
        mValue(mCount) = pValue
        mCount = mCount + 1
    End Sub

    Public Property Get Count()
        Count = mCount
    End Property

    ' Indice de un parametro por nombre (-1 si no existe).
    Public Function IndexOf(pName)
        Dim i
        IndexOf = -1
        For i = 0 To mCount - 1
            If LCase(mName(i)) = LCase(pName) Then
                IndexOf = i
                Exit Function
            End If
        Next
    End Function

    Public Function NameAt(i)  : NameAt  = mName(i)  : End Function
    Public Function TypeAt(i)  : TypeAt  = mType(i)  : End Function
    Public Function SizeAt(i)  : SizeAt  = mSize(i)  : End Function
    Public Function ValueAt(i) : ValueAt = mValue(i) : End Function
End Class

' ---------------------------------------------------------------------
'  DbOpen: abre una conexion. Intenta la cadena principal y, si el
'  proveedor rechaza palabras clave ODBC, reintenta con la de respaldo.
'  Devuelve Nothing si no es posible conectar.
' ---------------------------------------------------------------------
Function DbOpen()
    Dim conn
    On Error Resume Next
    Set conn = Server.CreateObject("ADODB.Connection")
    conn.ConnectionTimeout = 15
    conn.CommandTimeout = 0
    ' Cursor en cliente: permite desconectar los Recordset y cerrar la
    ' conexion inmediatamente, liberando el pool cuanto antes.
    conn.CursorLocation = adUseClient
    conn.Open DB_CONNECTION
    If Err.Number <> 0 Then
        LastDbError = Err.Description
        Err.Clear
        conn.Open DB_CONNECTION_FALLBACK
    End If
    If Err.Number <> 0 Then
        LastDbError = Err.Description
        Err.Clear
        Set conn = Nothing
    End If
    On Error GoTo 0
    Set DbOpen = conn
End Function

' ---------------------------------------------------------------------
'  BuildCommand: construye un ADODB.Command.
'
'  El proveedor SQLOLEDB no admite parametros con nombre en adCmdText,
'  solo marcadores posicionales ("?"). Para no sacrificar legibilidad,
'  aqui se traduce automaticamente cada marcador "@nombre" a "?" y se
'  anaden los parametros en el orden en que aparecen en el SQL.
'  Los valores siguen viajando SIEMPRE como parametros tipados, por lo
'  que la inyeccion SQL queda neutralizada.
' ---------------------------------------------------------------------
Function BuildCommand(conn, sql, params)
    Dim cmd, re, matches, i, idx, pName, pValue, finalSql
    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = conn
    cmd.CommandType = adCmdText

    If TypeName(params) <> "DbParams" Then
        cmd.CommandText = sql
        Set BuildCommand = cmd
        Exit Function
    End If

    Set re = New RegExp
    re.Global = True
    re.IgnoreCase = True
    re.Pattern = "@[A-Za-z_][A-Za-z0-9_]*"
    Set matches = re.Execute(sql)

    ' Validacion: todo marcador debe tener su parametro declarado.
    For i = 0 To matches.Count - 1
        If params.IndexOf(matches(i).Value) < 0 Then
            LastDbError = "Parametro no declarado en la consulta: " & matches(i).Value
            Set BuildCommand = Nothing
            Exit Function
        End If
    Next

    finalSql = re.Replace(sql, "?")
    cmd.CommandText = finalSql

    ' Los parametros se anaden en el orden de aparicion en el SQL.
    For i = 0 To matches.Count - 1
        pName = matches(i).Value
        idx = params.IndexOf(pName)
        pValue = params.ValueAt(idx)
        If IsNull(pValue) Then
            cmd.Parameters.Append cmd.CreateParameter( _
                "p" & i, params.TypeAt(idx), adParamInput)
        Else
            cmd.Parameters.Append cmd.CreateParameter( _
                "p" & i, params.TypeAt(idx), adParamInput, _
                params.SizeAt(idx), pValue)
        End If
    Next

    Set BuildCommand = cmd
End Function

' ---------------------------------------------------------------------
'  DbQuery: SELECT. Devuelve un Recordset desconectado (seguro de
'  recorrer tras cerrar la conexion). Nothing si hubo error.
' ---------------------------------------------------------------------
Function DbQuery(sql, params)
    Dim conn, cmd, rs
    Set DbQuery = Nothing
    Set conn = DbOpen()
    If conn Is Nothing Then Exit Function
    On Error Resume Next
    Set cmd = BuildCommand(conn, sql, params)
    If cmd Is Nothing Then
        conn.Close
        On Error GoTo 0
        Exit Function
    End If
    Set rs = cmd.Execute()
    If Err.Number <> 0 Then
        LastDbError = Err.Description
        Err.Clear
        conn.Close
        On Error GoTo 0
        Exit Function
    End If
    Set rs.ActiveConnection = Nothing
    conn.Close
    On Error GoTo 0
    Set DbQuery = rs
End Function

' ---------------------------------------------------------------------
'  DbScalar: devuelve el primer campo de la primera fila (o Null).
' ---------------------------------------------------------------------
Function DbScalar(sql, params)
    Dim rs
    DbScalar = Null
    Set rs = DbQuery(sql, params)
    If rs Is Nothing Then Exit Function
    If Not rs.EOF Then DbScalar = rs(0)
    rs.Close
End Function

' ---------------------------------------------------------------------
'  DbExec: INSERT / UPDATE / DELETE. Devuelve True si tuvo exito.
' ---------------------------------------------------------------------
Function DbExec(sql, params)
    Dim conn, cmd
    DbExec = False
    Set conn = DbOpen()
    If conn Is Nothing Then Exit Function
    On Error Resume Next
    Set cmd = BuildCommand(conn, sql, params)
    If cmd Is Nothing Then
        conn.Close
        On Error GoTo 0
        Exit Function
    End If
    cmd.Execute , , adExecuteNoRecords
    If Err.Number = 0 Then
        DbExec = True
    Else
        LastDbError = Err.Description
        Err.Clear
    End If
    conn.Close
    On Error GoTo 0
End Function

' ---------------------------------------------------------------------
'  DbInsertReturnId: INSERT y devuelve el IDENTITY generado.
'  SCOPE_IDENTITY() solo es valido dentro del MISMO lote, por lo que el
'  INSERT y la lectura del identificador se envian juntos en una unica
'  instruccion (separados por ";"). Se desactiva NOCOUNT para que ADO
'  reciba unicamente el Recordset del SELECT final.
' ---------------------------------------------------------------------
Function DbInsertReturnId(sql, params)
    Dim conn, cmd, rs, newId, wrapped
    DbInsertReturnId = 0
    Set conn = DbOpen()
    If conn Is Nothing Then Exit Function
    On Error Resume Next
    wrapped = "SET NOCOUNT ON; " & sql & "; SELECT CAST(SCOPE_IDENTITY() AS int) AS NEW_ID"
    Set cmd = BuildCommand(conn, wrapped, params)
    If cmd Is Nothing Then
        conn.Close
        On Error GoTo 0
        Exit Function
    End If
    Set rs = cmd.Execute()
    If Err.Number <> 0 Then
        LastDbError = Err.Description
        Err.Clear
        conn.Close
        On Error GoTo 0
        Exit Function
    End If
    newId = 0
    If Not rs Is Nothing Then
        If Not rs.EOF Then
            If Not IsNull(rs("NEW_ID")) Then newId = CLng(rs("NEW_ID"))
        End If
        rs.Close
    End If
    conn.Close
    On Error GoTo 0
    DbInsertReturnId = newId
End Function

' ---------------------------------------------------------------------
'  DbProbe: comprobacion de conectividad para la pantalla de diagnostico.
' ---------------------------------------------------------------------
Function DbProbe()
    Dim v
    v = DbScalar("SELECT COUNT(*) FROM TBL_SONG", Nothing)
    If IsNull(v) Then
        DbProbe = "ERROR: " & LastDbError
    Else
        DbProbe = "OK (" & v & " canciones)"
    End If
End Function
%>

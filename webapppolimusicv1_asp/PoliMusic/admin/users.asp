<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<!--#include virtual="/PoliMusic/includes/app.asp"-->
<%
' =====================================================================
'  admin/users.asp - CRUD de usuarios (listado + eliminacion)
'  Protecciones: no se puede borrar la propia cuenta ni el ultimo
'  administrador del sistema.
' =====================================================================
RequireAdmin()

Dim PageTitle, ActiveNav, AdminTab
PageTitle = "Administrar usuarios"
ActiveNav = "admin"
AdminTab = "users"

If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    CsrfCheck()
    Dim delId, p, adminsLeft, ownerPl
    delId = FormInt("id", 0)
    If FormS("action", 20) = "delete" And delId > 0 Then
        If delId = CurrentUserId() Then
            FlashSet "error", "No puedes eliminar tu propia cuenta mientras la usas."
        Else
            Set p = New DbParams
            p.Add "@id", adInteger, 0, delId
            Dim isTargetAdmin
            isTargetAdmin = (ToInt(DbScalar("SELECT USER_TYPE FROM TBL_USER WHERE ID_USER = @id", p), -1) = USER_TYPE_ADMIN)
            adminsLeft = ToInt(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE USER_TYPE = " & USER_TYPE_ADMIN, Nothing), 0)

            If isTargetAdmin And adminsLeft <= 1 Then
                FlashSet "error", "Debe existir al menos un administrador en el sistema."
            Else
                Set p = New DbParams
                p.Add "@id", adInteger, 0, delId
                ' Se eliminan primero las playlists del usuario y sus canciones.
                DbExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST IN " & _
                       "(SELECT ID_PLAYLIST FROM TBL_PLAYLIST WHERE ID_USER = @id)", p
                DbExec "DELETE FROM TBL_PLAYLIST WHERE ID_USER = @id", p
                If DbExec("DELETE FROM TBL_USER WHERE ID_USER = @id", p) Then
                    FlashSet "ok", "Usuario eliminado correctamente."
                Else
                    FlashSet "error", "No se pudo eliminar el usuario: " & LastDbError
                End If
            End If
        End If
    End If
    Response.Redirect APP_VROOT & "/admin/users.asp"
End If

Dim rs
%>
<!--#include virtual="/PoliMusic/includes/header.asp"-->

<div class="page-head">
    <div>
        <h1>Usuarios</h1>
        <p class="sub">Gestion de cuentas y perfiles de acceso.</p>
    </div>
    <div>
        <a class="btn btn--primary" href="<%=APP_VROOT%>/admin/user_edit.asp">+ Nuevo usuario</a>
    </div>
</div>

<!--#include file="nav.asp"-->

<%
Set rs = DbQuery("SELECT u.ID_USER, u.USERNAME, u.EMAIL, u.BIRTHDAY, u.USER_PHOTO, u.USER_TYPE, " & _
                 "(SELECT COUNT(*) FROM TBL_PLAYLIST p WHERE p.ID_USER = u.ID_USER) AS N " & _
                 "FROM TBL_USER u ORDER BY u.USER_TYPE DESC, u.USERNAME", Nothing)
If rs Is Nothing Then
    Response.Write "<div class=""notice notice--danger"">No se pudo consultar los usuarios: " & H(LastDbError) & "</div>"
ElseIf rs.EOF Then
    Response.Write EmptyState("profile", "Sin usuarios", "No hay usuarios registrados.")
Else
    Response.Write "<div class=""table-wrap""><table class=""data""><thead><tr>" & _
                   "<th></th><th>Usuario</th><th>Correo</th><th>Nacimiento</th>" & _
                   "<th>Perfil</th><th>Playlists</th><th></th></tr></thead><tbody>"
    Do While Not rs.EOF
        Response.Write "<tr>"
        Response.Write "<td><img class=""thumb thumb--round"" src=""" & HAttr(UserPhoto(rs("USER_PHOTO"))) & """ alt=""""></td>"
        Response.Write "<td>" & H(rs("USERNAME"))
        If CLng(rs("ID_USER")) = CurrentUserId() Then Response.Write " <span class=""tag"">tu</span>"
        Response.Write "</td>"
        Response.Write "<td>" & H(rs("EMAIL")) & "</td>"
        Response.Write "<td>" & H(FmtDate(rs("BIRTHDAY"))) & "</td>"
        Response.Write "<td><span class=""badge " & _
            IIf(CInt(rs("USER_TYPE")) = USER_TYPE_ADMIN, "badge-admin"">Administrador", "badge-user"">Usuario") & "</span></td>"
        Response.Write "<td>" & H(rs("N")) & "</td>"
        Response.Write "<td class=""actions"">" & _
            "<a class=""btn btn--fill btn--sm"" href=""" & APP_VROOT & "/admin/user_edit.asp?id=" & rs("ID_USER") & """>Editar</a>"
        If CLng(rs("ID_USER")) <> CurrentUserId() Then
            Response.Write MiniForm(APP_VROOT & "/admin/users.asp", _
                Hidden("action", "delete") & Hidden("id", rs("ID_USER")), _
                "Eliminar", "btn btn--danger btn--sm", "Eliminar el usuario, sus playlists y sus canciones?", "trash")
        End If
        Response.Write "</td></tr>"
        rs.MoveNext
    Loop
    Response.Write "</tbody></table></div>"
End If
%>

<!--#include virtual="/PoliMusic/includes/footer.asp"-->

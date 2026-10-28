<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV2.Song" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>PoliMusic &middot; Canciones</title>
    <style type="text/css">
        :root {
            --bg: #0a0a0c;
            --surface: rgba(24, 24, 27, 0.72);
            --card: #17171a;
            --card-hover: #232327;
            --text: #f5f5f7;
            --muted: #a1a1a6;
            --dim: #6e6e73;
            --accent: #1db954;
            --accent-hi: #1ed760;
            --line: rgba(255, 255, 255, 0.08);
            --radius: 18px;
        }

        * { box-sizing: border-box; }

        html, body { margin: 0; padding: 0; }

        body {
            min-height: 100vh;
            color: var(--text);
            background:
                radial-gradient(1100px 560px at 12% -12%, rgba(29, 185, 84, 0.20), transparent 62%),
                radial-gradient(900px 480px at 98% -6%, rgba(126, 96, 255, 0.16), transparent 58%),
                var(--bg);
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            -webkit-font-smoothing: antialiased;
            letter-spacing: -0.01em;
        }

        a { color: inherit; }

        /* ---------- Barra superior (vidrio, estilo Apple) ---------- */
        .topbar {
            position: sticky;
            top: 0;
            z-index: 30;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            padding: 14px 28px;
            background: rgba(10, 10, 12, 0.72);
            border-bottom: 1px solid var(--line);
            backdrop-filter: saturate(180%) blur(20px);
            -webkit-backdrop-filter: saturate(180%) blur(20px);
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 11px;
            font-size: 17px;
            font-weight: 700;
            letter-spacing: -0.03em;
        }

        .brand .mark {
            width: 28px;
            height: 28px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--accent-hi), #0c7a38);
            color: #04170a;
            font-size: 14px;
            font-weight: 800;
            line-height: 28px;
            text-align: center;
            box-shadow: 0 4px 14px rgba(29, 185, 84, 0.35);
        }

        .topbar-right {
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .user-chip {
            display: flex;
            align-items: center;
            gap: 9px;
            padding: 6px 14px 6px 6px;
            border: 1px solid var(--line);
            border-radius: 999px;
            background: rgba(255, 255, 255, 0.05);
            font-size: 13px;
            color: var(--muted);
        }

        .user-chip .avatar {
            width: 26px;
            height: 26px;
            border-radius: 50%;
            background: linear-gradient(135deg, #4b4b52, #26262b);
            color: var(--text);
            font-size: 11px;
            font-weight: 700;
            line-height: 26px;
            text-align: center;
            text-transform: uppercase;
        }

        .user-chip .who { color: var(--text); font-weight: 600; }

        .role-tag {
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: var(--accent-hi);
            border: 1px solid rgba(30, 215, 96, 0.35);
            border-radius: 6px;
            padding: 2px 6px;
        }

        /* ---------- Contenedor ---------- */
        .wrap {
            max-width: 1180px;
            margin: 0 auto;
            padding: 0 28px 56px;
        }

        .hero { padding: 46px 0 26px; }

        .eyebrow {
            display: block;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.16em;
            text-transform: uppercase;
            color: var(--accent-hi);
            margin-bottom: 10px;
        }

        .hero h1 {
            margin: 0;
            font-size: 44px;
            line-height: 1.06;
            font-weight: 700;
            letter-spacing: -0.04em;
        }

        .hero p {
            margin: 10px 0 0;
            font-size: 15px;
            color: var(--muted);
        }

        /* ---------- Layout de dos columnas ---------- */
        .layout {
            display: grid;
            grid-template-columns: minmax(0, 1fr) 330px;
            gap: 20px;
            align-items: start;
        }

        .panel {
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: var(--radius);
            backdrop-filter: blur(14px);
            -webkit-backdrop-filter: blur(14px);
            box-shadow: 0 18px 50px rgba(0, 0, 0, 0.42);
        }

        .panel-head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            padding: 20px 22px 14px;
        }

        .panel-head h2 {
            margin: 0;
            font-size: 19px;
            font-weight: 700;
            letter-spacing: -0.025em;
        }

        .pill {
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.06em;
            color: var(--muted);
            background: rgba(255, 255, 255, 0.06);
            border: 1px solid var(--line);
            border-radius: 999px;
            padding: 4px 11px;
        }

        .panel-body { padding: 0 12px 14px; }

        /* ---------- Lista de canciones (GridView como tracklist) ---------- */
        .songs-grid {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0 6px;
        }

        .songs-grid th {
            text-align: left;
            padding: 0 14px 4px;
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.14em;
            text-transform: uppercase;
            color: var(--dim);
        }

        .songs-grid td {
            padding: 11px 14px;
            vertical-align: middle;
            background: var(--card);
            border-top: 1px solid rgba(255, 255, 255, 0.04);
            border-bottom: 1px solid rgba(255, 255, 255, 0.04);
            font-size: 14px;
            transition: background 0.16s ease;
        }

        .songs-grid td:first-child {
            border-left: 1px solid rgba(255, 255, 255, 0.04);
            border-radius: 12px 0 0 12px;
        }

        .songs-grid td:last-child {
            border-right: 1px solid rgba(255, 255, 255, 0.04);
            border-radius: 0 12px 12px 0;
        }

        .songs-grid tr:hover td { background: var(--card-hover); }

        .song-name {
            font-weight: 600;
            letter-spacing: -0.015em;
        }

        .song-path {
            margin-top: 3px;
            font-size: 11px;
            color: var(--dim);
            font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
        }

        .plays {
            display: inline-block;
            min-width: 34px;
            padding: 3px 9px;
            border-radius: 999px;
            background: rgba(255, 255, 255, 0.06);
            font-size: 12px;
            font-weight: 600;
            color: var(--muted);
            text-align: center;
        }

        .row-actions {
            display: flex;
            gap: 7px;
            justify-content: flex-end;
        }

        /* Botón de play circular */
        .play {
            display: inline-block;
            width: 34px;
            height: 34px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.08);
            color: var(--text);
            font-size: 11px;
            line-height: 34px;
            text-align: center;
            text-decoration: none;
            transition: background 0.16s ease, transform 0.16s ease, color 0.16s ease;
        }

        .play:hover {
            background: var(--accent-hi);
            color: #04170a;
            transform: scale(1.08);
        }

        /* ---------- Botones ---------- */
        .btn {
            display: inline-block;
            padding: 9px 16px;
            border-radius: 11px;
            border: 1px solid var(--line);
            background: rgba(255, 255, 255, 0.06);
            color: var(--text);
            font-family: inherit;
            font-size: 13px;
            font-weight: 600;
            letter-spacing: -0.01em;
            text-decoration: none;
            cursor: pointer;
            transition: background 0.16s ease, transform 0.12s ease, border-color 0.16s ease;
        }

        .btn:hover { background: rgba(255, 255, 255, 0.11); }
        .btn:active { transform: scale(0.98); }

        .btn-sm { padding: 6px 11px; font-size: 12px; border-radius: 9px; }

        .btn-primary {
            background: linear-gradient(180deg, var(--accent-hi), #14a144);
            border-color: transparent;
            color: #04170a;
            font-weight: 700;
            box-shadow: 0 6px 18px rgba(29, 185, 84, 0.28);
        }

        .btn-primary:hover {
            background: linear-gradient(180deg, #2ae26c, #17ad49);
        }

        .btn-danger {
            color: #ff6b6b;
            border-color: rgba(255, 107, 107, 0.32);
            background: transparent;
        }

        .btn-danger:hover { background: rgba(255, 107, 107, 0.12); }

        /* ---------- Reproductor ---------- */
        .player-card {
            position: sticky;
            top: 92px;
            padding: 20px;
        }

        .art {
            width: 100%;
            aspect-ratio: 1 / 1;
            border-radius: 14px;
            background:
                radial-gradient(circle at 30% 25%, rgba(30, 215, 96, 0.85), transparent 55%),
                radial-gradient(circle at 75% 80%, rgba(126, 96, 255, 0.75), transparent 58%),
                linear-gradient(160deg, #26262b, #0e0e10);
            color: rgba(255, 255, 255, 0.9);
            font-size: 52px;
            line-height: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.06);
            margin-bottom: 16px;
        }

        .now-playing { margin-bottom: 14px; }

        .now-playing .label {
            display: block;
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.14em;
            text-transform: uppercase;
            color: var(--dim);
            margin-bottom: 6px;
        }

        .now-title {
            display: block;
            font-size: 17px;
            font-weight: 700;
            letter-spacing: -0.025em;
            line-height: 1.25;
        }

        .now-title.is-empty { color: var(--dim); font-weight: 500; }

        .player-card audio {
            width: 100%;
            height: 38px;
            display: block;
            border-radius: 10px;
            filter: invert(1) hue-rotate(180deg) saturate(0.6) opacity(0.92);
        }

        .player-meta {
            margin-top: 14px;
            font-size: 11px;
            color: var(--dim);
            line-height: 1.5;
        }

        /* ---------- Panel de administración ---------- */
        .admin-panel { margin-top: 20px; }

        .admin-body { padding: 0 22px 20px; }

        .form-grid {
            display: grid;
            grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
            gap: 16px;
        }

        .field label {
            display: block;
            margin-bottom: 7px;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            color: var(--dim);
        }

        .field input[type="text"] {
            width: 100%;
            padding: 12px 14px;
            border-radius: 12px;
            border: 1px solid var(--line);
            background: #101013;
            color: var(--text);
            font-family: inherit;
            font-size: 14px;
            outline: none;
            transition: border-color 0.16s ease, box-shadow 0.16s ease;
        }

        .field input[type="text"]:focus {
            border-color: rgba(30, 215, 96, 0.55);
            box-shadow: 0 0 0 4px rgba(30, 215, 96, 0.13);
        }

        .field input[type="file"] {
            width: 100%;
            padding: 9px 10px;
            border-radius: 12px;
            border: 1px dashed rgba(255, 255, 255, 0.16);
            background: #101013;
            color: var(--muted);
            font-family: inherit;
            font-size: 12px;
            cursor: pointer;
        }

        .field input[type="file"]:hover { border-color: rgba(30, 215, 96, 0.5); }

        .hint {
            display: block;
            margin-top: 7px;
            font-size: 11px;
            color: var(--dim);
        }

        .form-actions {
            display: flex;
            gap: 10px;
            align-items: center;
            margin-top: 18px;
        }

        /* ---------- Mensajes ---------- */
        .msg {
            display: block;
            margin-top: 16px;
            padding: 0;
            font-size: 13px;
            line-height: 1.5;
        }

        .msg.ok,
        .msg.err,
        .msg.info {
            padding: 11px 14px;
            border-radius: 11px;
        }

        .msg.ok {
            color: #7ef2a4;
            background: rgba(30, 215, 96, 0.10);
            border: 1px solid rgba(30, 215, 96, 0.28);
        }

        .msg.err {
            color: #ff9a9a;
            background: rgba(255, 107, 107, 0.10);
            border: 1px solid rgba(255, 107, 107, 0.28);
        }

        .msg.info {
            color: #cfc6ff;
            background: rgba(126, 96, 255, 0.12);
            border: 1px solid rgba(126, 96, 255, 0.28);
        }

        @media (max-width: 900px) {
            .layout { grid-template-columns: minmax(0, 1fr); }
            .player-card { position: static; }
            .hero h1 { font-size: 32px; }
            .form-grid { grid-template-columns: minmax(0, 1fr); }
            .wrap, .topbar { padding-left: 18px; padding-right: 18px; }
        }
    </style>
</head>
<body>
    <form id="formSong" runat="server">

        <header class="topbar">
            <div class="brand">
                <span class="mark">&#9835;</span>
                <span>PoliMusic</span>
            </div>
            <div class="topbar-right">
                <span class="user-chip">
                    <span class="avatar"><asp:Literal ID="litUserInitial" runat="server" /></span>
                    <span class="who"><asp:Literal ID="litUserName" runat="server" /></span>
                    <asp:Literal ID="litRole" runat="server" />
                </span>
                <a class="btn btn-sm" href="Logout.aspx">Salir</a>
            </div>
        </header>

        <div class="wrap">

            <section class="hero">
                <span class="eyebrow">Biblioteca</span>
                <h1>Tu m&uacute;sica, sin ruido.</h1>
                <p>Escucha tu cat&aacute;logo y administra las canciones de PoliMusic.</p>
            </section>

            <div class="layout">

                <section class="panel">
                    <div class="panel-head">
                        <h2>Canciones</h2>
                        <span class="pill"><asp:Literal ID="litSongCount" runat="server" Text="0" /> en la biblioteca</span>
                    </div>
                    <div class="panel-body">
                        <asp:GridView ID="gvSongs" runat="server"
                            AutoGenerateColumns="False"
                            DataKeyNames="ID_SONG"
                            CssClass="songs-grid"
                            GridLines="None"
                            EmptyDataText="A&uacute;n no hay canciones. Un administrador puede agregar la primera."
                            OnRowCommand="gvSongs_RowCommand"
                            OnRowDataBound="gvSongs_RowDataBound">
                            <Columns>
                                <asp:TemplateField HeaderStyle-Width="54px">
                                    <ItemTemplate>
                                        <asp:LinkButton ID="lnkPlay" runat="server" CssClass="play"
                                            CommandName="PlaySong"
                                            CommandArgument='<%# Eval("ID_SONG") %>'
                                            ToolTip="Reproducir">&#9654;</asp:LinkButton>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Canci&oacute;n">
                                    <ItemTemplate>
                                        <div class="song-name"><%# System.Web.HttpUtility.HtmlEncode(Convert.ToString(Eval("SONG_NAME"))) %></div>
                                        <div class="song-path"><%# System.Web.HttpUtility.HtmlEncode(Convert.ToString(Eval("SONG_PATH"))) %></div>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="Reproducciones" HeaderStyle-Width="150px">
                                    <ItemTemplate>
                                        <span class="plays"><%# Eval("PLAYS_TEXT") %></span>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:TemplateField HeaderText="" HeaderStyle-Width="160px">
                                    <ItemTemplate>
                                        <div class="row-actions">
                                            <asp:LinkButton ID="lnkEdit" runat="server" CssClass="btn btn-sm"
                                                CommandName="EditSong"
                                                CommandArgument='<%# Eval("ID_SONG") %>'>Editar</asp:LinkButton>
                                            <asp:LinkButton ID="lnkDelete" runat="server" CssClass="btn btn-danger btn-sm"
                                                CommandName="DeleteSong"
                                                CommandArgument='<%# Eval("ID_SONG") %>'
                                                OnClientClick="return confirm('¿Eliminar esta canción de la biblioteca?');">Eliminar</asp:LinkButton>
                                        </div>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                    </div>
                </section>

                <aside class="panel player-card">
                    <div class="art">&#9834;</div>
                    <div class="now-playing">
                        <span class="label">Reproduciendo ahora</span>
                        <asp:Literal ID="litNowPlaying" runat="server" />
                    </div>
                    <asp:Literal ID="litPlayer" runat="server" />
                    <div class="player-meta">Cada reproducci&oacute;n suma al contador de la canci&oacute;n.</div>
                </aside>

            </div>

            <asp:Panel ID="pnlAdmin" runat="server" CssClass="panel admin-panel">
                <div class="panel-head">
                    <h2>Panel de administraci&oacute;n</h2>
                    <span class="pill">Admin</span>
                </div>
                <div class="admin-body">
                    <asp:HiddenField ID="hfSongID" runat="server" Value="0" />
                    <div class="form-grid">
                        <div class="field">
                            <label>Nombre de la canci&oacute;n</label>
                            <asp:TextBox ID="txtSongName" runat="server" MaxLength="50" />
                        </div>
                        <div class="field">
                            <label>Archivo MP3</label>
                            <asp:FileUpload ID="fupSong" runat="server" />
                            <span class="hint">Solo .mp3. M&aacute;ximo 50 MB. Al editar, si no eliges archivo se conserva el actual.</span>
                        </div>
                    </div>
                    <div class="form-actions">
                        <asp:Button ID="btnSave" runat="server" CssClass="btn btn-primary"
                            Text="Agregar canción" OnClick="btnSave_Click" />
                        <asp:Button ID="btnCancel" runat="server" CssClass="btn"
                            Text="Cancelar" OnClick="btnCancel_Click" Visible="false" />
                    </div>
                    <asp:Label ID="lblMessage" runat="server" CssClass="msg" />
                </div>
            </asp:Panel>

        </div>

    </form>
</body>
</html>

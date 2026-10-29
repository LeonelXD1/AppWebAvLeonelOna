<%@ Page Title="Canciones" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV3.Song" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <style type="text/css">
        /* =========================================================
           PoliMusic · Canciones
           Lenguaje visual: la oscuridad y la lista de Spotify,
           la tipografia, el vidrio y los detalles de Apple.
           ========================================================= */
        :root {
            --pm-bg: #08080a;
            --pm-surface: rgba(24, 24, 28, 0.72);
            --pm-line: rgba(255, 255, 255, 0.08);
            --pm-line-strong: rgba(255, 255, 255, 0.16);
            --pm-text: #f5f5f7;
            --pm-muted: #a1a1a6;
            --pm-dim: #6e6e73;
            --pm-accent: #1ed760;
            --pm-accent-deep: #12a34b;
            --pm-radius: 20px;
            --pm-font: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Segoe UI", Inter, Roboto, Helvetica, Arial, sans-serif;
        }

        /* ---------- Lienzo oscuro (sobreescribe el tema del Master) ---------- */
        body {
            background-color: var(--pm-bg) !important;
            background-image:
                radial-gradient(900px 520px at 6% -10%, rgba(30, 215, 96, 0.16), transparent 60%),
                radial-gradient(820px 480px at 98% -6%, rgba(120, 92, 255, 0.16), transparent 62%) !important;
            background-repeat: no-repeat !important;
            background-attachment: fixed !important;
            color: var(--pm-text);
            font-family: var(--pm-font);
            letter-spacing: -0.01em;
            -webkit-font-smoothing: antialiased;
        }

        .body-content {
            margin-top: 0;
            padding: 0;
            max-width: none;
        }

        .navbar.bg-dark {
            background: rgba(8, 8, 10, 0.72) !important;
            border-bottom: 1px solid var(--pm-line);
            backdrop-filter: saturate(180%) blur(20px);
            -webkit-backdrop-filter: saturate(180%) blur(20px);
        }

        .navbar .navbar-brand {
            color: var(--pm-text) !important;
            font-weight: 700;
            letter-spacing: -0.03em;
        }

        .navbar .nav-link {
            color: var(--pm-muted) !important;
            font-size: 14px;
            font-weight: 500;
            padding: 7px 12px !important;
            border-radius: 10px;
            transition: color 0.2s ease, background 0.2s ease;
        }

        .navbar .nav-link:hover {
            color: var(--pm-text) !important;
            background: rgba(255, 255, 255, 0.07);
        }

        .body-content hr {
            border-top-color: var(--pm-line);
        }

        .body-content footer p {
            color: var(--pm-dim);
            font-size: 12px;
        }

        /* ---------- Contenedor ---------- */
        .pm {
            max-width: 1200px;
            margin: 0 auto;
            padding: 30px 28px 70px;
        }

        /* ---------- Encabezado tipo playlist ---------- */
        .hero {
            display: flex;
            align-items: flex-end;
            gap: 26px;
            padding: 6px 0 34px;
            flex-wrap: wrap;
        }

        .hero-art {
            position: relative;
            flex: 0 0 auto;
            width: 172px;
            height: 172px;
            border-radius: 24px;
            display: grid;
            place-items: center;
            overflow: hidden;
            background:
                radial-gradient(circle at 26% 20%, rgba(30, 215, 96, 0.95), transparent 58%),
                radial-gradient(circle at 80% 84%, rgba(120, 92, 255, 0.9), transparent 60%),
                linear-gradient(150deg, #1e1e24, #0a0a0c);
            box-shadow: 0 28px 64px rgba(0, 0, 0, 0.6), inset 0 0 0 1px rgba(255, 255, 255, 0.09);
        }

        .hero-art::after {
            content: "";
            position: absolute;
            inset: 0;
            background: linear-gradient(180deg, rgba(255, 255, 255, 0.14), transparent 46%);
            pointer-events: none;
        }

        .hero-art .glyph {
            font-size: 66px;
            line-height: 1;
            color: rgba(255, 255, 255, 0.94);
            filter: drop-shadow(0 10px 22px rgba(0, 0, 0, 0.5));
        }

        .hero-copy {
            flex: 1 1 320px;
            min-width: 0;
        }

        .eyebrow {
            display: block;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.18em;
            text-transform: uppercase;
            color: var(--pm-accent);
            margin-bottom: 12px;
        }

        .hero h1 {
            margin: 0;
            font-size: clamp(40px, 6vw, 62px);
            line-height: 1;
            font-weight: 700;
            letter-spacing: -0.045em;
        }

        .hero-meta {
            display: flex;
            align-items: center;
            gap: 9px;
            margin: 14px 0 0;
            font-size: 13.5px;
            color: var(--pm-muted);
        }

        .hero-meta .dot {
            width: 3px;
            height: 3px;
            border-radius: 50%;
            background: var(--pm-dim);
        }

        .hero-user {
            flex: 0 0 auto;
            padding-bottom: 6px;
        }

        .user-chip {
            display: inline-flex;
            align-items: center;
            gap: 9px;
            padding: 5px 14px 5px 5px;
            border: 1px solid var(--pm-line);
            border-radius: 999px;
            background: rgba(255, 255, 255, 0.05);
            font-size: 13px;
            color: var(--pm-muted);
        }

        .user-chip .avatar {
            width: 26px;
            height: 26px;
            border-radius: 50%;
            background: linear-gradient(135deg, #4b4b52, #232327);
            color: var(--pm-text);
            font-size: 11px;
            font-weight: 700;
            line-height: 26px;
            text-align: center;
            text-transform: uppercase;
        }

        .user-chip .who {
            color: var(--pm-text);
            font-weight: 600;
        }

        .role-tag {
            font-size: 9.5px;
            font-weight: 700;
            letter-spacing: 0.1em;
            text-transform: uppercase;
            color: var(--pm-accent);
            border: 1px solid rgba(30, 215, 96, 0.38);
            border-radius: 6px;
            padding: 2px 6px;
        }

        /* ---------- Layout ---------- */
        .layout {
            display: grid;
            grid-template-columns: minmax(0, 1fr) 336px;
            gap: 20px;
            align-items: start;
        }

        .panel {
            background: linear-gradient(180deg, rgba(28, 28, 33, 0.82), rgba(15, 15, 18, 0.92));
            border: 1px solid var(--pm-line);
            border-radius: var(--pm-radius);
            backdrop-filter: blur(18px);
            -webkit-backdrop-filter: blur(18px);
            box-shadow: 0 30px 70px rgba(0, 0, 0, 0.45);
            animation: pm-rise 0.55s cubic-bezier(0.22, 1, 0.36, 1) both;
        }

        @keyframes pm-rise {
            from { opacity: 0; transform: translateY(14px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .panel-head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 14px;
            padding: 20px 22px 12px;
            flex-wrap: wrap;
        }

        .panel-head h2 {
            margin: 0;
            font-size: 18px;
            font-weight: 700;
            letter-spacing: -0.03em;
        }

        .panel-body {
            padding: 0 10px 14px;
        }

        /* ---------- Buscador (estilo campo de busqueda de Apple) ---------- */
        .search {
            position: relative;
            display: flex;
            align-items: center;
            min-width: 210px;
        }

        .search svg {
            position: absolute;
            left: 11px;
            width: 14px;
            height: 14px;
            stroke: var(--pm-dim);
            fill: none;
            stroke-width: 2;
            pointer-events: none;
        }

        .search input {
            width: 100%;
            padding: 8px 12px 8px 32px;
            border-radius: 999px;
            border: 1px solid var(--pm-line);
            background: rgba(255, 255, 255, 0.05);
            color: var(--pm-text);
            font-family: inherit;
            font-size: 12.5px;
            max-width: none;
            outline: none;
            transition: border-color 0.18s ease, box-shadow 0.18s ease, background 0.18s ease;
        }

        .search input::placeholder { color: var(--pm-dim); }

        .search input:focus {
            background: rgba(255, 255, 255, 0.08);
            border-color: rgba(30, 215, 96, 0.55);
            box-shadow: 0 0 0 4px rgba(30, 215, 96, 0.12);
        }

        /* ---------- Lista de canciones ---------- */
        .songs-grid {
            width: 100%;
            table-layout: fixed;
            border-collapse: separate;
            border-spacing: 0 1px;
        }

        .songs-grid th {
            text-align: left;
            padding: 8px 14px;
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.16em;
            text-transform: uppercase;
            color: var(--pm-dim);
            border-bottom: 1px solid var(--pm-line);
            background: transparent;
        }

        .songs-grid td {
            padding: 9px 14px;
            vertical-align: middle;
            border: 0;
            background: transparent;
            font-size: 14px;
            color: var(--pm-text);
            transition: background 0.16s ease;
        }

        .songs-grid tr.track-row:hover td { background: rgba(255, 255, 255, 0.06); }
        .songs-grid tr.track-row:hover td:first-child { border-radius: 10px 0 0 10px; }
        .songs-grid tr.track-row:hover td:last-child { border-radius: 0 10px 10px 0; }

        .col-idx { width: 58px; }
        .col-plays { width: 132px; }
        .col-actions { width: 150px; }

        .track-idx {
            display: inline-block;
            width: 22px;
            text-align: right;
            font-size: 12.5px;
            font-variant-numeric: tabular-nums;
            color: var(--pm-dim);
        }

        .track-play {
            display: none;
            width: 30px;
            height: 30px;
            line-height: 30px;
            border-radius: 50%;
            background: var(--pm-accent);
            color: #04170a;
            font-size: 10px;
            text-align: center;
            text-decoration: none;
            box-shadow: 0 6px 16px rgba(30, 215, 96, 0.35);
            transition: transform 0.15s ease, background 0.15s ease;
        }

        .track-play:hover {
            background: #26ef6d;
            color: #04170a;
            transform: scale(1.08);
        }

        .track-row:hover .track-idx { display: none; }
        .track-row:hover .track-play { display: inline-block; }
        .track-row:hover .eq { display: none; }

        /* Ecualizador de la cancion que se esta reproduciendo */
        .eq {
            display: none;
            align-items: flex-end;
            gap: 2px;
            height: 14px;
            width: 20px;
            vertical-align: middle;
        }

        .eq i {
            display: block;
            width: 3px;
            height: 100%;
            border-radius: 2px;
            background: var(--pm-accent);
            transform-origin: bottom;
            animation: pm-eq 1s ease-in-out infinite;
        }

        .eq i:nth-child(2) { animation-delay: 0.22s; }
        .eq i:nth-child(3) { animation-delay: 0.44s; }

        @keyframes pm-eq {
            0%, 100% { transform: scaleY(0.3); }
            50% { transform: scaleY(1); }
        }

        .track-row.is-playing .track-idx { display: none; }
        .track-row.is-playing .eq { display: inline-flex; }
        .track-row.is-playing .song-name { color: var(--pm-accent); }
        .track-row.is-playing:hover .eq { display: none; }

        .song-name {
            font-weight: 600;
            font-size: 14.5px;
            letter-spacing: -0.015em;
            transition: color 0.16s ease;
        }

        .song-path {
            margin-top: 2px;
            font-size: 11.5px;
            color: var(--pm-dim);
            font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            max-width: 100%;
        }

        .plays {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 36px;
            padding: 4px 10px;
            border-radius: 999px;
            background: rgba(255, 255, 255, 0.06);
            border: 1px solid var(--pm-line);
            font-size: 12px;
            font-weight: 600;
            color: var(--pm-muted);
            font-variant-numeric: tabular-nums;
        }

        .row-actions {
            display: flex;
            gap: 7px;
            justify-content: flex-end;
        }

        .empty-row td {
            padding: 34px 16px;
            text-align: center;
            color: var(--pm-dim);
            font-size: 13.5px;
        }

        /* ---------- Botones ---------- */
        .btn-pm {
            display: inline-block;
            padding: 9px 16px;
            border-radius: 12px;
            border: 1px solid var(--pm-line);
            background: rgba(255, 255, 255, 0.06);
            color: var(--pm-text);
            font-family: inherit;
            font-size: 13px;
            font-weight: 600;
            letter-spacing: -0.01em;
            text-decoration: none;
            cursor: pointer;
            transition: background 0.16s ease, transform 0.12s ease, border-color 0.16s ease;
        }

        .btn-pm:hover {
            background: rgba(255, 255, 255, 0.12);
            color: var(--pm-text);
            text-decoration: none;
        }

        .btn-pm:active { transform: scale(0.975); }

        .btn-pm-sm {
            padding: 6px 12px;
            font-size: 12px;
            border-radius: 9px;
        }

        .btn-pm-primary {
            background: linear-gradient(180deg, var(--pm-accent), var(--pm-accent-deep));
            border-color: transparent;
            color: #04170a;
            font-weight: 700;
            box-shadow: 0 8px 22px rgba(30, 215, 96, 0.3);
        }

        .btn-pm-primary:hover {
            background: linear-gradient(180deg, #2ae66c, #16ad4f);
            color: #04170a;
        }

        .btn-pm-danger {
            color: #ff8b8b;
            border-color: rgba(255, 107, 107, 0.3);
            background: transparent;
        }

        .btn-pm-danger:hover {
            background: rgba(255, 107, 107, 0.13);
            color: #ffb3b3;
        }

        /* ---------- Reproductor ---------- */
        .player-card {
            position: sticky;
            top: 88px;
            padding: 18px;
        }

        .art {
            position: relative;
            width: 100%;
            aspect-ratio: 1 / 1;
            border-radius: 18px;
            display: grid;
            place-items: center;
            overflow: hidden;
            background:
                radial-gradient(circle at 28% 24%, rgba(30, 215, 96, 0.9), transparent 56%),
                radial-gradient(circle at 76% 82%, rgba(120, 92, 255, 0.85), transparent 58%),
                linear-gradient(160deg, #26262b, #0b0b0d);
            box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.08), 0 18px 44px rgba(0, 0, 0, 0.5);
            margin-bottom: 16px;
            transition: transform 0.5s cubic-bezier(0.22, 1, 0.36, 1);
        }

        .art .glyph {
            font-size: 54px;
            color: rgba(255, 255, 255, 0.92);
            filter: drop-shadow(0 8px 18px rgba(0, 0, 0, 0.45));
        }

        .player-card.is-playing .art { transform: scale(0.985); }

        .player-card.is-playing .art .glyph { animation: pm-breathe 3.2s ease-in-out infinite; }

        @keyframes pm-breathe {
            0%, 100% { transform: scale(1); opacity: 0.92; }
            50% { transform: scale(1.06); opacity: 1; }
        }

        .now-playing { margin-bottom: 14px; }

        .now-playing .label {
            display: block;
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.16em;
            text-transform: uppercase;
            color: var(--pm-dim);
            margin-bottom: 7px;
        }

        .now-title {
            display: block;
            font-size: 17px;
            font-weight: 700;
            letter-spacing: -0.03em;
            line-height: 1.28;
            word-break: break-word;
        }

        .now-title.is-empty {
            color: var(--pm-dim);
            font-weight: 500;
        }

        .player-card audio {
            width: 100%;
            height: 38px;
            display: block;
            border-radius: 999px;
            filter: invert(1) hue-rotate(180deg) saturate(0.62) opacity(0.9);
        }

        .player-empty {
            padding: 12px 14px;
            border: 1px dashed var(--pm-line-strong);
            border-radius: 12px;
            font-size: 12.5px;
            color: var(--pm-dim);
            line-height: 1.5;
        }

        .player-meta {
            margin: 14px 0 0;
            font-size: 11px;
            color: var(--pm-dim);
            line-height: 1.55;
        }

        .player-stat {
            display: flex;
            align-items: baseline;
            gap: 7px;
            margin-top: 10px;
            font-size: 12px;
            color: var(--pm-muted);
        }

        .player-stat strong {
            font-size: 16px;
            color: var(--pm-text);
            font-variant-numeric: tabular-nums;
        }

        /* ---------- Panel de administracion ---------- */
        .admin-panel { margin-top: 20px; }

        .admin-body { padding: 0 22px 20px; }

        .pill {
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.1em;
            text-transform: uppercase;
            color: var(--pm-accent);
            background: rgba(30, 215, 96, 0.1);
            border: 1px solid rgba(30, 215, 96, 0.28);
            border-radius: 999px;
            padding: 4px 11px;
        }

        .form-grid {
            display: grid;
            grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
            gap: 16px;
        }

        .field label {
            display: block;
            margin-bottom: 7px;
            font-size: 10.5px;
            font-weight: 700;
            letter-spacing: 0.1em;
            text-transform: uppercase;
            color: var(--pm-dim);
        }

        .field input[type="text"] {
            width: 100%;
            max-width: none;
            padding: 12px 14px;
            border-radius: 12px;
            border: 1px solid var(--pm-line);
            background: rgba(255, 255, 255, 0.04);
            color: var(--pm-text);
            font-family: inherit;
            font-size: 14px;
            outline: none;
            transition: border-color 0.18s ease, box-shadow 0.18s ease, background 0.18s ease;
        }

        .field input[type="text"]:focus {
            background: rgba(255, 255, 255, 0.07);
            border-color: rgba(30, 215, 96, 0.55);
            box-shadow: 0 0 0 4px rgba(30, 215, 96, 0.12);
        }

        .field input[type="file"] {
            width: 100%;
            max-width: none;
            padding: 9px 10px;
            border-radius: 12px;
            border: 1px dashed var(--pm-line-strong);
            background: rgba(255, 255, 255, 0.03);
            color: var(--pm-muted);
            font-family: inherit;
            font-size: 12px;
            cursor: pointer;
            transition: border-color 0.18s ease;
        }

        .field input[type="file"]:hover { border-color: rgba(30, 215, 96, 0.5); }

        .hint {
            display: block;
            margin-top: 7px;
            font-size: 11px;
            color: var(--pm-dim);
            line-height: 1.5;
        }

        .form-actions {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-top: 18px;
        }

        /* ---------- Mensajes ---------- */
        .msg {
            display: block;
            margin-top: 16px;
            font-size: 13px;
            line-height: 1.5;
        }

        .msg.ok, .msg.err, .msg.info {
            padding: 11px 14px;
            border-radius: 12px;
        }

        .msg.ok {
            color: #8ff7b1;
            background: rgba(30, 215, 96, 0.1);
            border: 1px solid rgba(30, 215, 96, 0.28);
        }

        .msg.err {
            color: #ffb0b0;
            background: rgba(255, 107, 107, 0.1);
            border: 1px solid rgba(255, 107, 107, 0.28);
        }

        .msg.info {
            color: #d3c9ff;
            background: rgba(120, 92, 255, 0.12);
            border: 1px solid rgba(120, 92, 255, 0.28);
        }

        /* ---------- Responsive ---------- */
        @media (max-width: 980px) {
            .layout { grid-template-columns: minmax(0, 1fr); }
            .player-card { position: static; }
            .form-grid { grid-template-columns: minmax(0, 1fr); }
            .pm { padding-left: 18px; padding-right: 18px; }
            .hero-art { width: 132px; height: 132px; border-radius: 20px; }
            .hero-art .glyph { font-size: 50px; }
            .col-actions { width: 132px; }
            .art { max-width: 280px; margin-left: auto; margin-right: auto; }
        }

        @media (max-width: 700px) {
            .pm { padding: 18px 14px 56px; }
            .hero { gap: 18px; padding-bottom: 26px; }
            .hero-art { width: 104px; height: 104px; border-radius: 18px; }
            .hero-art .glyph { font-size: 40px; }
            .hero h1 { font-size: 38px; }
            .hero-user { width: 100%; padding-bottom: 0; }
            .panel-head { padding: 16px 16px 10px; }
            .panel-body { padding: 0 8px 12px; }
            .search { min-width: 100%; }
            .songs-grid th, .songs-grid td { padding: 8px 9px; }
            .col-idx { width: 44px; }
            .col-plays { display: none; }
            .col-actions { width: 118px; }
            .row-actions { gap: 6px; }
            .btn-pm-sm { padding: 6px 9px; font-size: 11.5px; }
            .song-name { font-size: 13.5px; }
            .song-path { font-size: 10.5px; }
            .admin-body { padding: 0 16px 16px; }
            .art { max-width: 220px; }
        }

        /* En pantallas tactiles no existe el hover: el boton de reproducir debe verse siempre. */
        @media (hover: none) {
            .track-play { display: inline-block; }
            .track-row .track-idx { display: none; }
            .track-row.is-playing .eq { display: none; }
        }
    </style>

    <div class="pm">

        <!-- ================= Encabezado ================= -->
        <section class="hero">
            <div class="hero-art"><span class="glyph">&#9835;</span></div>

            <div class="hero-copy">
                <span class="eyebrow">Tu biblioteca</span>
                <h1>Canciones</h1>
                <p class="hero-meta">
                    <asp:Literal ID="litHeroMeta" runat="server" Text="0 canciones" />
                    <span class="dot"></span>
                    <span>PoliMusic</span>
                </p>
            </div>

            <div class="hero-user">
                <span class="user-chip">
                    <span class="avatar"><asp:Literal ID="litUserInitial" runat="server" /></span>
                    <span class="who"><asp:Literal ID="litUserName" runat="server" /></span>
                    <asp:Literal ID="litRole" runat="server" />
                </span>
            </div>
        </section>

        <!-- ================= Lista + reproductor ================= -->
        <div class="layout">

            <section class="panel list-panel">
                <div class="panel-head">
                    <h2>Todas las canciones</h2>
                    <div class="search">
                        <svg viewBox="0 0 24 24" aria-hidden="true">
                            <circle cx="11" cy="11" r="7"></circle>
                            <line x1="16.5" y1="16.5" x2="21" y2="21"></line>
                        </svg>
                        <input type="search" id="songFilter" placeholder="Buscar en la biblioteca" autocomplete="off" />
                    </div>
                </div>

                <div class="panel-body">
                    <asp:HiddenField ID="hfNowPlaying" runat="server" Value="0" />

                    <asp:GridView ID="gvSongs" runat="server"
                        AutoGenerateColumns="False"
                        DataKeyNames="ID_SONG"
                        CssClass="songs-grid"
                        GridLines="None"
                        ShowHeaderWhenEmpty="True"
                        EmptyDataText="Aún no hay canciones. Un administrador puede agregar la primera."
                        OnRowCommand="gvSongs_RowCommand"
                        OnRowDataBound="gvSongs_RowDataBound">
                        <EmptyDataRowStyle CssClass="empty-row" />
                        <Columns>
                            <asp:TemplateField HeaderText="#" HeaderStyle-CssClass="col-idx" ItemStyle-CssClass="col-idx">
                                <ItemTemplate>
                                    <span class="track-idx"><%# (Container.DataItemIndex + 1).ToString("00") %></span>
                                    <span class="eq"><i></i><i></i><i></i></span>
                                    <asp:LinkButton ID="lnkPlay" runat="server" CssClass="track-play"
                                        CommandName="PlaySong"
                                        CommandArgument='<%# Eval("ID_SONG") %>'
                                        ToolTip="Reproducir">&#9654;</asp:LinkButton>
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="Canción">
                                <ItemTemplate>
                                    <div class="song-name"><%# System.Web.HttpUtility.HtmlEncode(Convert.ToString(Eval("SONG_NAME"))) %></div>
                                    <div class="song-path"><%# System.Web.HttpUtility.HtmlEncode(Convert.ToString(Eval("SONG_PATH"))) %></div>
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="Reproducciones" HeaderStyle-CssClass="col-plays" ItemStyle-CssClass="col-plays">
                                <ItemTemplate>
                                    <span class="plays"><%# Eval("PLAYS_TEXT") %></span>
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="" HeaderStyle-CssClass="col-actions" ItemStyle-CssClass="col-actions">
                                <ItemTemplate>
                                    <div class="row-actions">
                                        <asp:LinkButton ID="lnkEdit" runat="server" CssClass="btn-pm btn-pm-sm"
                                            CommandName="EditSong"
                                            CommandArgument='<%# Eval("ID_SONG") %>'>Editar</asp:LinkButton>
                                        <asp:LinkButton ID="lnkDelete" runat="server" CssClass="btn-pm btn-pm-danger btn-pm-sm"
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
                <div class="art"><span class="glyph">&#9834;</span></div>

                <div class="now-playing">
                    <span class="label">Reproduciendo ahora</span>
                    <asp:Literal ID="litNowPlaying" runat="server" />
                </div>

                <asp:Literal ID="litPlayer" runat="server" />
                <asp:Literal ID="litPlayerMeta" runat="server" />

                <p class="player-meta">Cada reproducci&oacute;n suma al contador de la canci&oacute;n.</p>
            </aside>

        </div>

        <!-- ================= Administraci&oacute;n ================= -->
        <asp:Panel ID="pnlAdmin" runat="server" CssClass="panel admin-panel">
            <div class="panel-head">
                <h2>Panel de administraci&oacute;n</h2>
                <span class="pill">Administrador</span>
            </div>

            <div class="admin-body">
                <asp:HiddenField ID="hfSongID" runat="server" Value="0" />

                <div class="form-grid">
                    <div class="field">
                        <label for="txtSongName">Nombre de la canci&oacute;n</label>
                        <asp:TextBox ID="txtSongName" runat="server" MaxLength="50" />
                    </div>
                    <div class="field">
                        <label for="fupSong">Archivo MP3</label>
                        <asp:FileUpload ID="fupSong" runat="server" />
                        <span class="hint">Solo .mp3. M&aacute;ximo 50 MB. Al editar, si no eliges archivo se conserva el actual.</span>
                    </div>
                </div>

                <div class="form-actions">
                    <asp:Button ID="btnSave" runat="server" CssClass="btn-pm btn-pm-primary"
                        Text="Agregar canción" OnClick="btnSave_Click" />
                    <asp:Button ID="btnCancel" runat="server" CssClass="btn-pm"
                        Text="Cancelar" OnClick="btnCancel_Click" Visible="false" />
                </div>

                <asp:Label ID="lblMessage" runat="server" CssClass="msg" />
            </div>
        </asp:Panel>

    </div>

    <script type="text/javascript">
        (function () {
            var grid = document.getElementById('<%= gvSongs.ClientID %>');
            var filter = document.getElementById('songFilter');
            var playerCard = document.querySelector('.player-card');

            // --- Filtro instantaneo de la lista (sin postback) ---
            if (grid && filter) {
                var rows = grid.querySelectorAll('tr.track-row');

                filter.addEventListener('input', function () {
                    var term = this.value.toLowerCase().trim();
                    for (var i = 0; i < rows.length; i++) {
                        var text = (rows[i].textContent || rows[i].innerText || '').toLowerCase();
                        rows[i].style.display = (term === '' || text.indexOf(term) !== -1) ? '' : 'none';
                    }
                });

                // Enter no debe provocar un postback dentro del formulario del Master.
                filter.addEventListener('keydown', function (e) {
                    if (e.key === 'Enter') { e.preventDefault(); }
                });

                // Atajo "/" para enfocar el buscador, como en Spotify.
                document.addEventListener('keydown', function (e) {
                    if (e.key === '/' && document.activeElement !== filter) {
                        e.preventDefault();
                        filter.focus();
                    }
                });

                // Toda la fila es clicable: delega el clic en el boton de reproducir.
                grid.addEventListener('click', function (e) {
                    if (e.target.closest('a, button, input, select, textarea')) { return; }
                    var row = e.target.closest('tr.track-row');
                    if (!row) { return; }
                    var play = row.querySelector('.track-play');
                    if (play) { play.click(); }
                });
            }

            // --- Estado visual del reproductor ---
            var audio = playerCard ? playerCard.querySelector('audio') : null;
            if (audio && playerCard) {
                audio.addEventListener('play', function () { playerCard.classList.add('is-playing'); });
                audio.addEventListener('pause', function () { playerCard.classList.remove('is-playing'); });
                audio.addEventListener('ended', function () { playerCard.classList.remove('is-playing'); });
            }
        })();
    </script>

</asp:Content>

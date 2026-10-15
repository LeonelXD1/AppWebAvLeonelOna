/* Captura de pantallas de PoliMusic para verificacion visual.
   Uso: node tools/screenshot.js <usuario> <clave> <light|dark> [carpeta]

   Nota: en este entorno el navegador headless deja de recibir entrada de
   raton real despues de la primera navegacion, asi que las interacciones
   se provocan con eventos DOM y con CSS.forcePseudoState, que es
   exactamente lo que dispara el navegador ante un clic o un hover. */
const puppeteer = require("puppeteer-core");
const path = require("path");
const fs = require("fs");

const CHROME = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const BASE = process.env.PM_BASE || "http://localhost:8085/PoliMusic";

const USER = process.argv[2] || "userAdmin";
const PASS = process.argv[3] || "12345678";
const THEME = process.argv[4] || "dark";
const OUT = process.argv[5] || path.join(__dirname, "..", "_shots", THEME);

const SHOTS = [
    ["03-home", "/home.asp"],
    ["04-songs", "/songs.asp"],
    ["05-albums", "/albums.asp"],
    ["06-album", "/album.asp?id=1"],
    ["07-artists", "/artists.asp"],
    ["08-artist", "/artist.asp?id=3"],
    ["09-playlists", "/playlists.asp"],
    ["10-playlist", "/playlist.asp?id=2"],
    ["11-playlist-form", "/playlist_form.asp"],
    ["12-playlist-add", "/playlist_add.asp?song_id=1"],
    ["13-profile", "/profile.asp"],
    ["14-search", "/search.asp?q=gabriel"],
    ["15-admin", "/admin/index.asp"],
    ["16-admin-songs", "/admin/songs.asp"],
    ["17-admin-song-edit", "/admin/song_edit.asp?id=1"],
    ["18-admin-album-edit", "/admin/album_edit.asp?id=1"],
    ["19-admin-playlists", "/admin/playlists.asp"],
    ["20-admin-users", "/admin/users.asp"],
    ["21-admin-diagnostico", "/admin/diagnostico.asp"]
];

const wait = ms => new Promise(r => setTimeout(r, ms));

async function forceHover(page, selector) {
    const client = await page.createCDPSession();
    await client.send("DOM.enable");
    await client.send("CSS.enable");
    const { root } = await client.send("DOM.getDocument");
    const { nodeId } = await client.send("DOM.querySelector", { nodeId: root.nodeId, selector });
    if (nodeId) {
        await client.send("CSS.forcePseudoState", { nodeId, forcedPseudoClasses: ["hover"] });
    }
    await client.detach();
}

(async () => {
    fs.mkdirSync(OUT, { recursive: true });

    const browser = await puppeteer.launch({
        executablePath: CHROME,
        headless: "new",
        args: [
            "--no-sandbox",
            "--disable-gpu",
            "--hide-scrollbars",
            "--window-size=1500,980",
            "--autoplay-policy=no-user-gesture-required"
        ]
    });
    const page = await browser.newPage();
    await page.setViewport({ width: 1500, height: 980, deviceScaleFactor: 1 });

    await page.evaluateOnNewDocument(function (theme) {
        try { localStorage.setItem("polimusic.theme", theme); } catch (e) { }
    }, THEME);

    const shot = async (name, url) => {
        await page.goto(BASE + url, { waitUntil: "networkidle2", timeout: 30000 });
        await wait(340);
        await page.screenshot({ path: path.join(OUT, name + ".png") });
        console.log("ok   " + name);
    };

    // 1) Pantallas de acceso
    await shot("01-login", "/login.asp");
    await shot("02-register", "/register.asp");

    // 2) Inicio de sesion (primer documento: aqui si funciona el clic real)
    await page.goto(BASE + "/login.asp", { waitUntil: "networkidle2" });
    await page.type("#username", USER);
    await page.type("#password", PASS);
    await Promise.all([
        page.waitForNavigation({ waitUntil: "networkidle2" }),
        page.click("button[type=submit]")
    ]);

    // 3) Resto de pantallas
    for (const [name, url] of SHOTS) {
        try { await shot(name, url); }
        catch (e) { console.log("FAIL " + name + " : " + e.message); }
    }

    // 4) Estado hover sobre una tarjeta
    try {
        await page.goto(BASE + "/albums.asp", { waitUntil: "networkidle2" });
        await forceHover(page, ".card");
        await wait(500);
        await page.screenshot({ path: path.join(OUT, "22-hover-card.png") });
        console.log("ok   22-hover-card");
    } catch (e) { console.log("FAIL hover : " + e.message); }

    // 5) Reproductor en marcha
    try {
        await page.goto(BASE + "/songs.asp", { waitUntil: "networkidle2" });
        await page.waitForSelector(".track[data-play]");
        await page.evaluate(() => { document.querySelector(".track[data-play]").click(); });
        await wait(2200);
        const estado = await page.evaluate(() => ({
            titulo: document.getElementById("np-title").textContent,
            sonando: document.querySelectorAll(".track.is-playing").length
        }));
        await page.screenshot({ path: path.join(OUT, "23-playing.png") });
        console.log("ok   23-playing  (" + estado.titulo + ", " + estado.sonando + " fila activa)");
    } catch (e) { console.log("FAIL playing : " + e.message); }

    // 6) Resultados de busqueda
    try { await shot("24-search-results", "/search.asp?q=a"); }
    catch (e) { console.log("FAIL search : " + e.message); }

    await browser.close();
    console.log("\nCapturas (" + THEME + ") en: " + OUT);
})().catch(e => { console.error("ERROR:", e.message); process.exit(1); });

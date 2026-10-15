/* =====================================================================
   PoliMusic - assets/js/app.js
   Comportamiento e interaccion.

   Se apoya en PM (spring.js) para todo lo que el usuario puede tocar:
   los muelles se re-enganchan desde el valor y la velocidad actuales,
   asi que cualquier animacion puede interrumpirse o revertirse sin
   saltos. Las transiciones CSS se reservan para cambios de estado que
   no se agarran con el dedo (color, fondo, opacidad).
   ===================================================================== */
(function () {
    "use strict";

    var PM = window.PM;
    var STORE = "polimusic.player.v2";
    var THEME_KEY = "polimusic.theme";

    var APP = (document.querySelector('meta[name="app-root"]') || {}).content || "";
    var CSRF = (document.querySelector('meta[name="csrf"]') || {}).content || "";

    var ICON_SUN = "<svg class='icon' width='18' height='18' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='1.7' stroke-linecap='round' stroke-linejoin='round'><circle cx='12' cy='12' r='4'/><path d='M12 2.6v2.2M12 19.2v2.2M2.6 12h2.2M19.2 12h2.2'/><path d='M5.5 5.5 7.1 7.1M16.9 16.9l1.6 1.6M18.5 5.5 16.9 7.1M7.1 16.9l-1.6 1.6'/></svg>";
    var ICON_MOON = "<svg class='icon' width='18' height='18' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='1.7' stroke-linecap='round' stroke-linejoin='round'><path d='M20.2 14.7A8.7 8.7 0 0 1 9.3 3.8a8.8 8.8 0 1 0 10.9 10.9z'/></svg>";
    var ICON_PLAY = "<svg class='icon' width='18' height='18' viewBox='0 0 24 24'><path d='M8.2 5.6v12.8L18.8 12z' fill='currentColor'/></svg>";
    var ICON_PAUSE = "<svg class='icon' width='18' height='18' viewBox='0 0 24 24'><rect x='8.5' y='5.6' width='2.7' height='12.8' rx='1.2' fill='currentColor'/><rect x='12.8' y='5.6' width='2.7' height='12.8' rx='1.2' fill='currentColor'/></svg>";

    /* =============================================================
       Tema: sigue al sistema salvo que el usuario elija lo contrario
       ============================================================= */
    function setupTheme() {
        var root = document.documentElement;
        var btn = document.querySelector("[data-theme-toggle]");
        if (!btn) { return; }

        function current() {
            var attr = root.getAttribute("data-theme");
            if (attr === "light" || attr === "dark") { return attr; }
            return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
        }
        function paint() {
            var dark = current() === "dark";
            btn.innerHTML = dark ? ICON_SUN : ICON_MOON;
            var label = dark ? "Cambiar a apariencia clara" : "Cambiar a apariencia oscura";
            btn.setAttribute("aria-label", label);
            btn.setAttribute("title", label);
        }
        btn.addEventListener("click", function () {
            var next = current() === "dark" ? "light" : "dark";
            root.setAttribute("data-theme", next);
            try { localStorage.setItem(THEME_KEY, next); } catch (e) { }
            paint();
        });
        if (window.matchMedia) {
            var mq = window.matchMedia("(prefers-color-scheme: dark)");
            var onChange = function () { if (!root.getAttribute("data-theme")) { paint(); } };
            if (mq.addEventListener) { mq.addEventListener("change", onChange); }
            else if (mq.addListener) { mq.addListener(onChange); }
        }
        paint();
    }

    /* =============================================================
       Control segmentado: el indicador se coloca con un muelle
       ============================================================= */
    function setupSegmented() {
        var groups = document.querySelectorAll(".segmented");
        Array.prototype.forEach.call(groups, function (group) {
            var thumb = group.querySelector(".segmented__thumb");
            var selected = group.querySelector("a.is-selected");
            if (!thumb || !selected) { return; }

            var tx = new PM.Spring({
                damping: 1, response: 0.34,
                onUpdate: function (v) { thumb.style.transform = "translateX(" + v + "px)"; }
            });
            var tw = new PM.Spring({
                damping: 1, response: 0.34,
                onUpdate: function (v) { thumb.style.width = v + "px"; }
            });

            function target() {
                var gr = group.getBoundingClientRect();
                var sr = selected.getBoundingClientRect();
                return { x: sr.left - gr.left + group.scrollLeft - 2, w: sr.width };
            }

            var t = target();
            tx.jump(t.x);
            tw.jump(0);

            /* "Materializar" en lugar de aparecer: el indicador llega
               creciendo desde su posicion, no como un fundido plano. */
            requestAnimationFrame(function () {
                tw.set(t.w);
                tx.set(t.x);
            });

            window.addEventListener("resize", function () {
                var n = target();
                tx.jump(n.x); tw.jump(n.w);
            });
        });
    }

    /* =============================================================
       Carrusel: arrastre 1:1, banda elastica y proyeccion de momento
       ============================================================= */
    function setupCarousels() {
        var items = document.querySelectorAll("[data-carousel]");
        Array.prototype.forEach.call(items, function (el) {
            var dragging = false;
            var pointerId = null;
            var startX = 0;
            var startScroll = 0;
            var tracker = new PM.VelocityTracker(6);
            var anim = null;
            var step = 0;

            function measure() {
                var first = el.firstElementChild;
                if (!first) { return; }
                var style = getComputedStyle(el);
                var gap = parseFloat(style.columnGap) || 0;
                step = first.getBoundingClientRect().width + gap;
            }

            function maxScroll() {
                return Math.max(0, el.scrollWidth - el.clientWidth);
            }

            function snapTo(projected, velocity) {
                var max = maxScroll();
                var index = step > 0 ? Math.round(projected / step) : 0;
                var target = PM.clamp(index * step, 0, max);
                el.style.scrollSnapType = "none";
                if (anim) { anim.stop(); }
                anim = new PM.Spring({
                    from: el.scrollLeft,
                    damping: 0.85,
                    response: 0.34,
                    onUpdate: function (v) { el.scrollLeft = v; },
                    onComplete: function () { el.style.scrollSnapType = ""; }
                });
                anim.set(target, velocity);
            }

            el.addEventListener("pointerdown", function (e) {
                if (e.pointerType === "touch") { return; }  /* el tactil ya trae inercia nativa */
                if (e.button !== 0) { return; }
                dragging = true;
                pointerId = e.pointerId;
                el.setPointerCapture(pointerId);
                startX = e.clientX;
                startScroll = el.scrollLeft;
                measure();
                tracker.reset();
                tracker.add(e.clientX, PM.now());
                if (anim) { anim.stop(); }
                el.style.scrollSnapType = "none";
                el.classList.add("is-dragging");
            });

            el.addEventListener("pointermove", function (e) {
                if (!dragging) { return; }
                var dx = e.clientX - startX;
                tracker.add(e.clientX, PM.now());
                var wanted = startScroll - dx;
                var max = maxScroll();
                if (wanted < 0) {
                    el.scrollLeft = -PM.rubberband(-wanted, el.clientWidth);
                } else if (wanted > max) {
                    el.scrollLeft = max + PM.rubberband(wanted - max, el.clientWidth);
                } else {
                    el.scrollLeft = wanted;
                }
            });

            function release() {
                if (!dragging) { return; }
                dragging = false;
                el.classList.remove("is-dragging");
                if (pointerId !== null) {
                    try { el.releasePointerCapture(pointerId); } catch (e) { }
                    pointerId = null;
                }
                /* La velocidad del gesto se entrega al muelle: no hay
                   costura entre arrastrar y animar. */
                var velocity = -tracker.velocity();
                var projected = el.scrollLeft + PM.project(velocity, 0.998);
                snapTo(projected, velocity);
            }

            el.addEventListener("pointerup", release);
            el.addEventListener("pointercancel", release);
            window.addEventListener("resize", measure);
            measure();
        });
    }

    /* =============================================================
       Reproductor
       ============================================================= */
    function setupPlayer() {
        var audio = document.getElementById("audio");
        if (!audio) { return null; }

        var el = {
            art: document.getElementById("np-cover"),
            title: document.getElementById("np-title"),
            artist: document.getElementById("np-sub"),
            play: document.getElementById("btn-play"),
            prev: document.getElementById("btn-prev"),
            next: document.getElementById("btn-next"),
            cur: document.getElementById("t-cur"),
            dur: document.getElementById("t-dur"),
            scrub: document.getElementById("scrub"),
            fill: document.getElementById("scrub-fill"),
            thumb: document.getElementById("scrub-thumb"),
            vol: document.getElementById("vol"),
            volIcon: document.getElementById("vol-icon")
        };

        var state = { items: [], index: -1, position: 0, playing: false, volume: 0.8 };
        var playScale = null;
        var counted = {};

        function fmt(sec) {
            if (!isFinite(sec) || sec < 0) { return "0:00"; }
            var m = Math.floor(sec / 60), s = Math.floor(sec % 60);
            return m + ":" + (s < 10 ? "0" : "") + s;
        }

        function load() {
            try {
                var raw = sessionStorage.getItem(STORE);
                if (raw) {
                    var parsed = JSON.parse(raw);
                    if (parsed && parsed.items && parsed.items.length) { state = parsed; }
                }
            } catch (e) { }
            try {
                var v = parseFloat(localStorage.getItem("polimusic.volume"));
                if (!isNaN(v)) { state.volume = v; }
            } catch (e) { }
        }

        function save() {
            try { sessionStorage.setItem(STORE, JSON.stringify(state)); } catch (e) { }
        }

        function current() {
            if (state.index < 0 || state.index >= state.items.length) { return null; }
            return state.items[state.index];
        }

        function paint() {
            var t = current();
            if (!t) {
                el.title.textContent = "Sin reproduccion";
                el.artist.textContent = "Selecciona una cancion para empezar";
                el.art.style.visibility = "hidden";
                el.play.innerHTML = ICON_PLAY;
                document.querySelectorAll(".track.is-playing").forEach(function (n) {
                    n.classList.remove("is-playing");
                });
                return;
            }
            el.art.style.visibility = "visible";
            el.art.src = t.cover || "";
            el.title.textContent = t.title;
            el.artist.textContent = t.artist || "";
            el.play.innerHTML = state.playing ? ICON_PAUSE : ICON_PLAY;
            document.querySelectorAll(".track").forEach(function (n) {
                n.classList.toggle("is-playing", n.getAttribute("data-id") === String(t.id));
            });
            document.title = (state.playing ? "\u25B6 " : "") + t.title + " \u00B7 PoliMusic";
        }

        /* Rebote sutil del boton al arrancar: retroalimentacion de exito */
        function popPlayButton() {
            if (PM.isReduced()) { return; }
            if (!playScale) {
                playScale = new PM.Spring({
                    from: 1, damping: 0.6, response: 0.3,
                    onUpdate: function (v) { el.play.style.transform = "scale(" + v + ")"; },
                    onComplete: function () { el.play.style.transform = ""; }
                });
            }
            playScale.set(1.08);
            setTimeout(function () { playScale.set(1); }, 90);
        }

        function registerPlay(id) {
            if (!id || counted[id]) { return; }
            counted[id] = true;
            try {
                fetch(APP + "/play.asp", {
                    method: "POST",
                    headers: { "Content-Type": "application/x-www-form-urlencoded" },
                    body: "id=" + encodeURIComponent(id) + "&csrf=" + encodeURIComponent(CSRF),
                    keepalive: true
                }).catch(function () { });
            } catch (e) { }
        }

        function setSrc(t, autoplay, position) {
            audio.src = t.url;
            audio.volume = state.volume;
            if (el.vol) { el.vol.value = state.volume; }
            updateVolIcon();
            if (position > 0) {
                audio.addEventListener("loadedmetadata", function once() {
                    audio.removeEventListener("loadedmetadata", once);
                    try { audio.currentTime = position; } catch (e) { }
                });
            }
            if (autoplay) { play(); }
        }

        function play() {
            var t = current();
            if (!t) { return; }
            if (!t.url) {
                el.artist.textContent = "Archivo de audio no disponible";
                next();
                return;
            }
            var p = audio.play();
            if (p && p.catch) {
                p.catch(function () { state.playing = false; save(); paint(); });
            }
        }

        function playAt(index, items) {
            if (items && items.length) { state.items = items; state.index = index; }
            else if (index !== undefined) { state.index = index; }
            var t = current();
            if (!t) { return; }
            state.position = 0;
            state.playing = true;
            setSrc(t, true, 0);
            registerPlay(t.id);
            save();
            paint();
        }

        function next() {
            if (state.index + 1 >= state.items.length) { state.playing = false; save(); paint(); return; }
            playAt(state.index + 1);
        }

        function prev() {
            if (audio.currentTime > 3) { audio.currentTime = 0; return; }
            if (state.index > 0) { playAt(state.index - 1); }
        }

        /* ---------- Cola ---------- */
        function readTrack(node) {
            return {
                id: node.getAttribute("data-id"),
                title: node.getAttribute("data-title") || "",
                artist: node.getAttribute("data-artist") || "",
                url: node.getAttribute("data-url") || "",
                cover: node.getAttribute("data-cover") || ""
            };
        }

        function queueFrom(node) {
            var box = node.closest("[data-queue]");
            if (!box) { return { items: [readTrack(node)], index: 0 }; }
            var nodes = box.querySelectorAll("[data-id][data-url]");
            var items = [], index = 0, i, n;
            for (i = 0; i < nodes.length; i++) {
                n = nodes[i];
                if (!n.getAttribute("data-url")) { continue; }
                if (n === node) { index = items.length; }
                items.push(readTrack(n));
            }
            if (!items.length) { return { items: [readTrack(node)], index: 0 }; }
            return { items: items, index: index };
        }

        document.addEventListener("click", function (ev) {
            var trigger = ev.target.closest("[data-play]");
            if (!trigger) { return; }
            ev.preventDefault();
            var t = readTrack(trigger);
            if (!t.url) {
                el.title.textContent = t.title;
                el.artist.textContent = "Archivo de audio no disponible";
                return;
            }
            var q = queueFrom(trigger);
            playAt(q.index, q.items);
        });

        el.play.addEventListener("click", function () {
            if (!current()) {
                var first = document.querySelector("[data-id][data-url]");
                if (first) { var q = queueFrom(first); playAt(q.index, q.items); }
                return;
            }
            if (audio.paused) { play(); } else { audio.pause(); }
        });
        el.next.addEventListener("click", next);
        el.prev.addEventListener("click", prev);

        /* ---------- Atajos de teclado ---------- */
        document.addEventListener("keydown", function (ev) {
            if (/^(INPUT|TEXTAREA|SELECT)$/.test(ev.target.tagName)) { return; }
            if (ev.code === "Space") { ev.preventDefault(); el.play.click(); }
            else if (ev.code === "ArrowRight" && ev.shiftKey) { next(); }
            else if (ev.code === "ArrowLeft" && ev.shiftKey) { prev(); }
        });

        /* ---------- Eventos del audio ---------- */
        audio.addEventListener("play", function () {
            if (!state.playing) { popPlayButton(); }
            state.playing = true; save(); paint();
        });
        audio.addEventListener("pause", function () { state.playing = false; save(); paint(); });
        audio.addEventListener("ended", next);
        audio.addEventListener("loadedmetadata", function () {
            if (el.dur) { el.dur.textContent = fmt(audio.duration); }
        });
        audio.addEventListener("error", function () {
            if (!audio.src) { return; }
            el.artist.textContent = "No se pudo cargar el audio";
        });

        window.addEventListener("pagehide", save);
        window.addEventListener("beforeunload", save);

        /* ---------- Barra de progreso (1:1, sin animacion) ---------- */
        function setupScrub() {
            if (!el.scrub) { return; }
            var dragging = false;
            var pointerId = null;
            var previewRatio = 0;

            function ratioFrom(clientX) {
                var r = el.scrub.getBoundingClientRect();
                return PM.clamp((clientX - r.left) / r.width, 0, 1);
            }
            function render(ratio) {
                var pct = (ratio * 100).toFixed(3) + "%";
                el.fill.style.width = pct;
                el.thumb.style.left = pct;
            }
            function track(e) {
                previewRatio = ratioFrom(e.clientX);
                render(previewRatio);
                var d = audio.duration;
                if (isFinite(d) && d > 0 && el.cur) { el.cur.textContent = fmt(previewRatio * d); }
            }

            el.scrub.addEventListener("pointerdown", function (e) {
                if (e.button !== 0 && e.pointerType === "mouse") { return; }
                dragging = true;
                pointerId = e.pointerId;
                el.scrub.setPointerCapture(pointerId);
                el.scrub.classList.add("is-active", "is-scrubbing");
                track(e);
            });
            el.scrub.addEventListener("pointermove", function (e) {
                if (!dragging) { return; }
                track(e);
            });
            function release() {
                if (!dragging) { return; }
                dragging = false;
                el.scrub.classList.remove("is-scrubbing");
                if (pointerId !== null) {
                    try { el.scrub.releasePointerCapture(pointerId); } catch (e) { }
                    pointerId = null;
                }
                var d = audio.duration;
                if (isFinite(d) && d > 0) {
                    try { audio.currentTime = previewRatio * d; } catch (e) { }
                    state.position = previewRatio * d;
                    save();
                }
                el.scrub.classList.remove("is-active");
            }
            el.scrub.addEventListener("pointerup", release);
            el.scrub.addEventListener("pointercancel", release);

            audio.addEventListener("timeupdate", function () {
                if (dragging) { return; }
                state.position = audio.currentTime;
                var d = audio.duration;
                if (isFinite(d) && d > 0) { render(audio.currentTime / d); }
                if (el.cur) { el.cur.textContent = fmt(audio.currentTime); }
            });
        }

        /* ---------- Volumen ---------- */
        function updateVolIcon() {
            if (!el.volIcon) { return; }
            var muted = state.volume <= 0.001;
            el.volIcon.innerHTML = muted
                ? "<svg class='icon' width='17' height='17' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='1.7' stroke-linecap='round' stroke-linejoin='round'><path d='M4.4 9.4h3.2L11.8 5.6v12.8L7.6 14.6H4.4z'/><path d='M15.4 10.2 19.6 14'/><path d='M19.6 10.2 15.4 14'/></svg>"
                : "<svg class='icon' width='17' height='17' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='1.7' stroke-linecap='round' stroke-linejoin='round'><path d='M4.4 9.4h3.2L11.8 5.6v12.8L7.6 14.6H4.4z'/><path d='M15.3 9.7a3.4 3.4 0 0 1 0 4.6'/><path d='M18 7.3a7 7 0 0 1 0 9.4'/></svg>";
        }
        if (el.vol) {
            el.vol.addEventListener("input", function () {
                state.volume = parseFloat(el.vol.value);
                audio.volume = state.volume;
                try { localStorage.setItem("polimusic.volume", state.volume); } catch (e) { }
                updateVolIcon();
            });
        }

        /* ---------- Arranque ---------- */
        load();
        setupScrub();
        var t = current();
        if (t) {
            setSrc(t, state.playing, state.position);
            paint();
        } else {
            paint();
        }
        return { audio: audio };
    }

    /* =============================================================
       Inicio
       ============================================================= */
    function boot() {
        setupTheme();
        setupSegmented();
        setupCarousels();
        setupPlayer();
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", boot);
    } else {
        boot();
    }
})();

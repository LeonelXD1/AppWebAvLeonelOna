/* =====================================================================
   PoliMusic - assets/js/spring.js
   Motor de muelles (springs) y utilidades de gesto.

   Traduce a la web los dos parametros con los que Apple describe el
   movimiento en "Designing Fluid Interfaces" (WWDC 2018):

     * damping  -> relacion de amortiguamiento (1.0 = sin rebote,
                   < 1.0 = rebota)
     * response -> rapidez con la que se alcanza el objetivo, en
                   segundos. NO es una "duracion": un muelle no tiene
                   duracion fija, su tiempo de asentamiento emerge de
                   los parametros.

   La propiedad clave es la INTERRUMPIBILIDAD: cada vez que se cambia el
   objetivo, el muelle se re-engancha desde el valor y la velocidad que
   tiene EN ESE INSTANTE, nunca desde el valor logico de destino. Asi el
   movimiento puede agarrarse y revertirse a mitad de vuelo sin saltos.
   ===================================================================== */
(function (global) {
    "use strict";

    /* ---------------- Preferencias del usuario ---------------- */
    var reducedMotion = false;
    var mqMotion = global.matchMedia ? global.matchMedia("(prefers-reduced-motion: reduce)") : null;

    function syncMotionPref() { reducedMotion = mqMotion ? mqMotion.matches : false; }
    if (mqMotion) {
        syncMotionPref();
        if (mqMotion.addEventListener) { mqMotion.addEventListener("change", syncMotionPref); }
        else if (mqMotion.addListener) { mqMotion.addListener(syncMotionPref); }
    }

    /* ---------------- Utilidades numericas ---------------- */
    function clamp(v, min, max) { return v < min ? min : (v > max ? max : v); }

    /* Proyeccion de momento (apartado 6 de la guia): dado que el gesto
       llevaba una velocidad, estima donde acabaria de forma natural.
       Es la forma exponencial que usa Apple, no v^2/(2a). */
    function project(initialVelocity, decelerationRate) {
        var d = decelerationRate == null ? 0.998 : decelerationRate;
        return (initialVelocity / 1000) * d / (1 - d);
    }

    /* Banda elastica (apartado 9): cuanto mas se pasa del limite, menos
       acompana el elemento. Un tope duro se lee como "congelado"; la
       resistencia progresiva se lee como "responde, pero no hay mas". */
    function rubberband(overshoot, dimension, constant) {
        var c = constant == null ? 0.55 : constant;
        return (overshoot * dimension * c) / (dimension + c * Math.abs(overshoot));
    }

    /* ---------------- Rastreador de velocidad ---------------- */
    /* Necesitamos la velocidad en el momento de soltar, no solo la
       ultima posicion: de ahi guardar un historial corto de muestras. */
    function VelocityTracker(sampleCount) {
        this.max = sampleCount || 6;
        this.history = [];
    }
    VelocityTracker.prototype.reset = function () { this.history.length = 0; };
    VelocityTracker.prototype.add = function (value, time) {
        this.history.push({ v: value, t: time });
        while (this.history.length > this.max) { this.history.shift(); }
    };
    VelocityTracker.prototype.velocity = function () {
        var h = this.history;
        if (h.length < 2) { return 0; }
        var newest = h[h.length - 1];
        var oldest = h[0];
        var dt = (newest.t - oldest.t) / 1000;
        if (dt <= 0) { return 0; }
        return (newest.v - oldest.v) / dt;
    };

    /* ---------------- Muelle ---------------- */
    function Spring(options) {
        options = options || {};
        this.value = options.from != null ? options.from : 0;
        this.velocity = options.velocity || 0;
        this.target = this.value;
        this.damping = options.damping != null ? options.damping : 1;
        this.response = options.response != null ? options.response : 0.4;
        this.restDelta = options.restDelta != null ? options.restDelta : 0.01;
        this.restSpeed = options.restSpeed != null ? options.restSpeed : 0.01;
        this.onUpdate = options.onUpdate || function () { };
        this.onComplete = options.onComplete || null;

        this._x0 = this.value;
        this._v0 = this.velocity;
        this._t0 = 0;
        this._running = false;
    }

    /* Cambia el objetivo conservando el estado actual: esto es lo que
       hace que el muelle sea interrumpible y reversible. */
    Spring.prototype.set = function (target, velocity) {
        this.target = target;
        if (velocity != null) { this.velocity = velocity; }
        this._x0 = this.value;
        this._v0 = this.velocity;
        this._t0 = now();
        if (!this._running) {
            this._running = true;
            Driver.add(this);
        }
    };

    /* Salto inmediato (sin movimiento). */
    Spring.prototype.jump = function (value) {
        this.value = value;
        this.target = value;
        this.velocity = 0;
        this._running = false;
        this.onUpdate(this.value);
    };

    Spring.prototype.stop = function () {
        this._running = false;
        Driver.remove(this);
    };

    Spring.prototype.isRunning = function () { return this._running; };

    /* Avanza el muelle. Devuelve false cuando ya ha llegado al reposo. */
    Spring.prototype.step = function (time) {
        var damping = this.damping;
        var response = this.response;

        /* Con "reducir movimiento" el muelle sigue existiendo, pero se
           vuelve criticamente amortiguado y muy corto: es un cambio de
           estado, no un desplazamiento llamativo. */
        if (reducedMotion) {
            damping = 1;
            if (response > 0.22) { response = 0.22; }
        }

        var w0 = (2 * Math.PI) / Math.max(0.02, response);
        var t = (time - this._t0) / 1000;
        var x0 = this._x0 - this.target;
        var v0 = this._v0;
        var x, v, e;

        if (damping < 1) {
            /* Subamortiguado: oscila y se asienta. */
            var wd = w0 * Math.sqrt(1 - damping * damping);
            e = Math.exp(-damping * w0 * t);
            var c1 = x0;
            var c2 = (v0 + damping * w0 * x0) / wd;
            var cos = Math.cos(wd * t);
            var sin = Math.sin(wd * t);
            x = e * (c1 * cos + c2 * sin);
            v = e * (-damping * w0 * (c1 * cos + c2 * sin) + (-c1 * wd * sin + c2 * wd * cos));
        } else if (damping === 1) {
            /* Criticamente amortiguado: sin rebote. */
            e = Math.exp(-w0 * t);
            var a = x0;
            var b = v0 + w0 * x0;
            x = (a + b * t) * e;
            v = (b - w0 * (a + b * t)) * e;
        } else {
            /* Sobreamortiguado: se aproxima sin llegar a oscilar. */
            var s = Math.sqrt(damping * damping - 1) * w0;
            e = Math.exp(-damping * w0 * t);
            var A = x0;
            var B = (v0 + damping * w0 * x0) / s;
            var cosh = Math.cosh(s * t);
            var sinh = Math.sinh(s * t);
            x = e * (A * cosh + B * sinh);
            v = e * (-damping * w0 * (A * cosh + B * sinh) + (A * s * sinh + B * s * cosh));
        }

        this.value = this.target + x;
        this.velocity = v;

        if (Math.abs(x) < this.restDelta && Math.abs(v) < this.restSpeed) {
            this.value = this.target;
            this.velocity = 0;
            this._running = false;
            this.onUpdate(this.value);
            if (this.onComplete) { this.onComplete(); }
            return false;
        }

        this.onUpdate(this.value);
        return true;
    };

    /* ---------------- Bucle unico compartido ---------------- */
    /* Todos los muelles avanzan en un solo requestAnimationFrame: es el
       reloj sincronizado con la pantalla. */
    var Driver = {
        springs: [],
        running: false,
        add: function (s) {
            if (this.springs.indexOf(s) < 0) { this.springs.push(s); }
            this.start();
        },
        remove: function (s) {
            var i = this.springs.indexOf(s);
            if (i >= 0) { this.springs.splice(i, 1); }
        },
        start: function () {
            if (this.running) { return; }
            this.running = true;
            var self = this;
            requestAnimationFrame(function tick(time) {
                for (var i = self.springs.length - 1; i >= 0; i--) {
                    if (!self.springs[i].step(time)) { self.springs.splice(i, 1); }
                }
                if (self.springs.length) { requestAnimationFrame(tick); }
                else { self.running = false; }
            });
        }
    };

    function now() {
        return (global.performance && global.performance.now) ? global.performance.now() : Date.now();
    }

    /* ---------------- Valores de referencia de Apple ---------------- */
    /* Reposicionar / mover          -> damping 1.0, response 0.4
       Rotacion                      -> damping 0.8, response 0.4
       Panel deslizante              -> damping 0.8, response 0.3
       Retroalimentacion al pulsar   -> damping 1.0, response 0.2  */
    var PRESETS = {
        move: { damping: 1.0, response: 0.4 },
        rotate: { damping: 0.8, response: 0.4 },
        sheet: { damping: 0.8, response: 0.3 },
        press: { damping: 1.0, response: 0.2 }
    };

    global.PM = global.PM || {};
    global.PM.Spring = Spring;
    global.PM.Driver = Driver;
    global.PM.VelocityTracker = VelocityTracker;
    global.PM.project = project;
    global.PM.rubberband = rubberband;
    global.PM.clamp = clamp;
    global.PM.isReduced = function () { return reducedMotion; };
    global.PM.PRESETS = PRESETS;
    global.PM.now = now;
})(window);

<%
' =====================================================================
'  PoliMusic - includes/footer.asp
'  Cierre del area principal + reproductor persistente.
'
'  El reproductor es una capa funcional translucida: el contenido pasa
'  por debajo y se desvanece justo antes de encontrarse con el cromo.
' =====================================================================
%>
        </div><!-- /.main__inner -->
    </main>
</div><!-- /.app -->

<div class="player" id="player">
    <div class="player__now">
        <img class="player__art" id="np-cover" alt="Caratula" src="<%=APP_VROOT%>/assets/img/default-cover.png" style="visibility:hidden">
        <div class="player__info grow">
            <div class="player__title" id="np-title">Sin reproduccion</div>
            <div class="player__artist" id="np-sub">Selecciona una cancion para empezar</div>
        </div>
    </div>

    <div class="player__center">
        <div class="player__transport">
            <button type="button" class="pbtn" id="btn-prev" title="Anterior" aria-label="Pista anterior"><%=Icon("prev", 20)%></button>
            <button type="button" class="pbtn pbtn--play" id="btn-play" title="Reproducir o pausar" aria-label="Reproducir"><%=Icon("play", 18)%></button>
            <button type="button" class="pbtn" id="btn-next" title="Siguiente" aria-label="Pista siguiente"><%=Icon("next", 20)%></button>
        </div>
        <div class="player__bar">
            <span class="player__time" id="t-cur">0:00</span>
            <div class="scrub" id="scrub" role="slider" tabindex="0"
                 aria-label="Progreso de la reproduccion" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0">
                <div class="scrub__track"><div class="scrub__fill" id="scrub-fill"></div></div>
                <div class="scrub__thumb" id="scrub-thumb"></div>
            </div>
            <span class="player__time" id="t-dur">0:00</span>
        </div>
    </div>

    <div class="player__right">
        <div class="player__volume">
            <span id="vol-icon" aria-hidden="true"><%=Icon("volume", 17)%></span>
            <input type="range" id="vol" min="0" max="1" step="0.01" value="0.8" aria-label="Volumen">
        </div>
    </div>

    <audio id="audio" preload="metadata"></audio>
</div>

<script src="<%=APP_VROOT%>/assets/js/spring.js"></script>
<script src="<%=APP_VROOT%>/assets/js/app.js"></script>
</body>
</html>

#!/usr/bin/env bash
# =====================================================================
#  PoliMusic - prueba de humo contra IIS Express
#  Uso:  tools/smoke.sh [usuario] [clave] [url1 url2 ...]
#  Sin argumentos: inicia sesion como LeonelOna y recorre las paginas
#  principales del perfil estandar.
# =====================================================================
set -u
BASE="${POLIMUSIC_BASE:-http://localhost:8085/PoliMusic}"
USER_NAME="${1:-LeonelOna}"
USER_PASS="${2:-123456789}"
shift 2 2>/dev/null || true

JAR="$(mktemp)"
URLS=("$@")
if [ ${#URLS[@]} -eq 0 ]; then
  URLS=("/home.asp" "/songs.asp" "/albums.asp" "/album.asp?id=1" "/artists.asp" \
        "/artist.asp?id=1" "/playlists.asp" "/playlist.asp?id=1" "/profile.asp" \
        "/search.asp?q=a" "/admin/index.asp")
fi

# --- login ---
curl -s -c "$JAR" -o /tmp/pm_login.html --max-time 15 "$BASE/login.asp"
TOKEN=$(grep -o 'name="csrf" value="[^"]*"' /tmp/pm_login.html | sed 's/.*value="//;s/"//')
if [ -z "$TOKEN" ]; then
  echo "!! No se pudo obtener el token CSRF (la pagina de login no cargo)"
  exit 1
fi
CODE=$(curl -s -b "$JAR" -c "$JAR" -o /dev/null -w "%{http_code}" --max-time 15 \
  -d "csrf=$TOKEN&username=$USER_NAME&password=$USER_PASS" "$BASE/login.asp")
echo "login $USER_NAME -> HTTP $CODE"
echo "--------------------------------------------------------------------"

for u in "${URLS[@]}"; do
  code=$(curl -s -b "$JAR" -o /tmp/pm_last.html -w "%{http_code}" --max-time 20 "$BASE$u")
  printf "%-34s -> %s\n" "$u" "$code"
  if [ "$code" = "500" ]; then
    echo "   --- error ASP ---"
    sed 's/<[^>]*>//g' /tmp/pm_last.html | grep -i -E "error|linea|línea" | head -4 | sed 's/^/   /'
  fi
done
rm -f "$JAR"

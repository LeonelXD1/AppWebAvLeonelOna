"""
Generador de assets para el clon de Spotify (PoliMusic).
Crea imagenes de album/artista/usuario en tonos azules y pistas MP3 de relleno
para los archivos referenciados en BDD_PoliMusic.sql que no vienen en la
carpeta SongFilesAndImages_resources.
"""
import math
import os
import struct
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(BASE, "PoliMusic", "assets")

# ---------------- Paleta (tonos azules) ----------------
BG_TOP = (8, 16, 30)
BG_BOTTOM = (14, 32, 60)
ACCENT = (29, 122, 252)      # azul principal
ACCENT_2 = (56, 189, 248)    # cian
ACCENT_3 = (99, 102, 241)    # indigo
INK = (241, 245, 249)

PALETTES = [
    ((13, 71, 161), (41, 182, 246)),
    ((21, 101, 192), (100, 181, 246)),
    ((26, 35, 126), (63, 81, 181)),
    ((2, 119, 189), (77, 208, 225)),
    ((40, 53, 147), (124, 77, 255)),
]


def font(size):
    for name in ("seguisb.ttf", "segoeui.ttf", "arialbd.ttf", "arial.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def vgradient(size, c1, c2):
    w, h = size
    img = Image.new("RGB", (1, h))
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        px[0, y] = (
            int(c1[0] + (c2[0] - c1[0]) * t),
            int(c1[1] + (c2[1] - c1[1]) * t),
            int(c1[2] + (c2[2] - c1[2]) * t),
        )
    return img.resize((w, h), Image.BILINEAR)


def radial_glow(img, center, radius, color, strength=120):
    w, h = img.size
    glow = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(glow)
    steps = 26
    for i in range(steps, 0, -1):
        r = radius * i / steps
        v = int(strength * (1 - i / steps) ** 1.6)
        d.ellipse([center[0] - r, center[1] - r, center[0] + r, center[1] + r], fill=v)
    glow = glow.filter(ImageFilter.GaussianBlur(radius * 0.18))
    layer = Image.new("RGB", (w, h), color)
    return Image.composite(Image.blend(img, layer, 0.85), img, glow)


def add_noise(img, amount=6):
    px = img.load()
    w, h = img.size
    rnd = random.Random(7)
    for _ in range(int(w * h * 0.08)):
        x = rnd.randrange(w)
        y = rnd.randrange(h)
        r, g, b = px[x, y]
        n = rnd.randint(-amount, amount)
        px[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n)), max(0, min(255, b + n)))
    return img


def draw_waveform(d, box, bars, color, seed):
    rnd = random.Random(seed)
    x0, y0, x1, y1 = box
    mid = (y0 + y1) / 2
    gap = (x1 - x0) / bars
    bw = max(2, gap * 0.55)
    for i in range(bars):
        t = i / max(1, bars - 1)
        env = math.sin(math.pi * t) ** 0.7
        h = (y1 - y0) * 0.5 * env * rnd.uniform(0.35, 1.0)
        cx = x0 + i * gap + gap / 2
        d.rounded_rectangle([cx - bw / 2, mid - h, cx + bw / 2, mid + h], radius=bw / 2, fill=color)


def album_cover(path, title, year, idx):
    size = 640
    c1, c2 = PALETTES[idx % len(PALETTES)]
    img = vgradient((size, size), BG_TOP, c1)
    img = radial_glow(img, (size * 0.72, size * 0.26), size * 0.62, c2, 150)
    img = radial_glow(img, (size * 0.18, size * 0.85), size * 0.5, ACCENT_3, 110)

    d = ImageDraw.Draw(img, "RGBA")
    # anillos concentricos
    for i in range(6):
        r = size * (0.18 + i * 0.09)
        d.ellipse([size * 0.5 - r, size * 0.5 - r, size * 0.5 + r, size * 0.5 + r],
                  outline=(255, 255, 255, 22), width=2)
    draw_waveform(d, (size * 0.12, size * 0.62, size * 0.88, size * 0.86),
                  bars=34, color=(255, 255, 255, 170), seed=idx * 13 + 5)
    d.rectangle([0, size - 6, size, size], fill=ACCENT_2)
    img = add_noise(img)

    d = ImageDraw.Draw(img)
    f_title = font(56)
    f_sub = font(26)
    words = title.split()
    lines, cur = [], ""
    for w in words:
        probe = (cur + " " + w).strip()
        if d.textlength(probe, font=f_title) > size * 0.72 and cur:
            lines.append(cur)
            cur = w
        else:
            cur = probe
    if cur:
        lines.append(cur)
    y = size * 0.14
    for ln in lines[:2]:
        d.text((size * 0.12, y), ln, font=f_title, fill=INK)
        y += 62
    d.text((size * 0.12, y + 6), str(year), font=f_sub, fill=(200, 224, 255))
    img.save(path, "PNG", optimize=True)


def artist_image(path, name, lastname, idx, ext):
    size = 560
    c1, c2 = PALETTES[(idx + 2) % len(PALETTES)]
    img = vgradient((size, size), BG_TOP, c1)
    img = radial_glow(img, (size * 0.5, size * 0.34), size * 0.66, c2, 140)
    d = ImageDraw.Draw(img, "RGBA")
    for i in range(7):
        r = size * (0.16 + i * 0.075)
        d.ellipse([size * 0.5 - r, size * 0.52 - r, size * 0.5 + r, size * 0.52 + r],
                  outline=(255, 255, 255, 20), width=2)
    # silueta cabeza + hombros (deja libre la franja inferior del rotulo)
    head_r = size * 0.145
    cy = size * 0.38
    d.ellipse([size * 0.5 - head_r, cy - head_r, size * 0.5 + head_r, cy + head_r],
              fill=(6, 12, 24, 235))
    sh_w, sh_h = size * 0.33, size * 0.20
    d.rounded_rectangle([size * 0.5 - sh_w, cy + head_r * 0.72, size * 0.5 + sh_w, cy + head_r * 0.72 + sh_h * 1.55],
                        radius=sh_h * 0.6, fill=(6, 12, 24, 235))
    # franja inferior para el rotulo
    scrim_top = int(size * 0.80)
    for y in range(scrim_top, size):
        t = (y - scrim_top) / max(1, size - scrim_top)
        d.line([(0, y), (size, y)], fill=(6, 12, 24, int(60 + 175 * t)))
    img = add_noise(img)
    d = ImageDraw.Draw(img)
    f = font(40)
    initials = (name[:1] + lastname[:1]).upper()
    d.text((size * 0.5, cy), initials, font=f, fill=ACCENT_2, anchor="mm")
    f_name = font(34)
    label = f"{name} {lastname}".strip()
    d.text((size * 0.5, size * 0.92), label, font=f_name, fill=INK, anchor="mm")
    img.save(path, "JPEG" if ext == "jpg" else "PNG", quality=88, optimize=True)


def user_avatar(path, initials, idx, ext="png"):
    size = 400
    c1, c2 = PALETTES[idx % len(PALETTES)]
    img = vgradient((size, size), BG_BOTTOM, c2)
    img = radial_glow(img, (size * 0.5, size * 0.42), size * 0.6, c1, 150)
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse([size * 0.12, size * 0.12, size * 0.88, size * 0.88], outline=(255, 255, 255, 40), width=3)
    img = add_noise(img, 4)
    d = ImageDraw.Draw(img)
    d.text((size * 0.5, size * 0.5), initials, font=font(140), fill=INK, anchor="mm")
    img.save(path, "JPEG" if ext == "jpg" else "PNG", quality=88, optimize=True)


def generic_placeholder(path, kind, ext="png"):
    size = 600
    img = vgradient((size, size), BG_TOP, (17, 34, 62))
    img = radial_glow(img, (size * 0.5, size * 0.45), size * 0.62, ACCENT, 120)
    d = ImageDraw.Draw(img, "RGBA")
    if kind == "music":
        d.ellipse([size * 0.28, size * 0.28, size * 0.72, size * 0.72], outline=(255, 255, 255, 90), width=8)
        d.ellipse([size * 0.42, size * 0.42, size * 0.58, size * 0.58], fill=(255, 255, 255, 200))
    elif kind == "user":
        d.ellipse([size * 0.34, size * 0.20, size * 0.66, size * 0.52], fill=(255, 255, 255, 210))
        d.rounded_rectangle([size * 0.20, size * 0.58, size * 0.80, size * 0.98], radius=90,
                            fill=(255, 255, 255, 210))
    elif kind == "list":
        for i, y in enumerate((0.30, 0.45, 0.60)):
            d.rounded_rectangle([size * 0.22, size * y, size * (0.78 - i * 0.06), size * (y + 0.06)],
                                radius=14, fill=(255, 255, 255, 200))
    img = add_noise(img, 4)
    img.save(path, "JPEG" if ext == "jpg" else "PNG", quality=88, optimize=True)


# ---------------- Audio de relleno ----------------
def tone_mp3(path, seed, seconds=24, base=196.0, tempo=0.5, scale=(0, 2, 4, 7, 9, 12, 14, 16)):
    import lameenc
    rate = 44100
    rnd = random.Random(seed)
    total = int(rate * seconds)
    buf = bytearray()
    step = int(rate * tempo)
    note_i = 0
    # pad de fondo + arpegio
    while len(buf) < total * 2:
        seg = min(step, total - len(buf) // 2)
        if seg <= 0:
            break
        semis = scale[note_i % len(scale)]
        freq = base * (2 ** (semis / 12.0))
        for n in range(seg):
            t = n / rate
            env = min(1.0, n / (rate * 0.02)) * min(1.0, (seg - n) / (rate * 0.12))
            v = (
                0.55 * math.sin(2 * math.pi * freq * t)
                + 0.25 * math.sin(2 * math.pi * freq * 2 * t)
                + 0.12 * math.sin(2 * math.pi * freq * 0.5 * t)
            )
            pad = 0.18 * math.sin(2 * math.pi * (base / 2) * t)
            s = max(-1.0, min(1.0, (v * env + pad) * 0.6))
            buf += struct.pack("<h", int(s * 30000))
        note_i += 1
    pcm = bytes(buf[: total * 2])
    enc = lameenc.Encoder()
    enc.set_bit_rate(128)
    enc.set_in_sample_rate(rate)
    enc.set_channels(1)
    enc.set_quality(5)
    data = enc.encode(pcm)
    data += enc.flush()
    with open(path, "wb") as fh:
        fh.write(data)


def main():
    rnd = random.Random(2026)

    # Albumes (referenciados en BDD como ~/albumImages/albumN.png)
    albums = ["Rock Album", "Relax Music", "Retro Album Music", "Classic Album", "Country Album"]
    years = [1976, 2000, 1980, 1950, 1990]
    out = os.path.join(ASSETS, "albumImages")
    os.makedirs(out, exist_ok=True)
    for i, (t, y) in enumerate(zip(albums, years), start=1):
        album_cover(os.path.join(out, f"album{i}.png"), t, y, i - 1)

    # Artistas (artist1..4 .jpg, artist5 .png segun la BDD)
    artists = [("Juan", "Gabriel", "jpg"), ("Ana", "Gabriel", "jpg"),
               ("Mariah", "Carey", "jpg"), ("Elvis", "Presley", "jpg"),
               ("Edward", "Sheeran", "png")]
    out = os.path.join(ASSETS, "artistImages")
    os.makedirs(out, exist_ok=True)
    for i, (n, l, ext) in enumerate(artists, start=1):
        artist_image(os.path.join(out, f"artist{i}.{ext}"), n, l, i, ext)

    # Avatar de usuario referenciado en la BDD (username1.png)
    out = os.path.join(ASSETS, "userImages")
    os.makedirs(out, exist_ok=True)
    user_avatar(os.path.join(out, "username1.png"), "U1", 2, "png")
    user_avatar(os.path.join(out, "leonelona.png"), "LO", 4, "png")
    user_avatar(os.path.join(out, "admin.png"), "AD", 1, "png")

    # Placeholders genericos
    out = os.path.join(ASSETS, "img")
    os.makedirs(out, exist_ok=True)
    generic_placeholder(os.path.join(out, "default-cover.png"), "music")
    generic_placeholder(os.path.join(out, "default-user.png"), "user")
    generic_placeholder(os.path.join(out, "default-playlist.png"), "list")

    # Pistas MP3 de relleno (la carpeta solo trae bensound-adventure.mp3)
    out = os.path.join(ASSETS, "songFiles")
    os.makedirs(out, exist_ok=True)
    tracks = [
        ("bensound-dreams.mp3", 11, 220.0, 0.62),
        ("bensound-energy.mp3", 22, 261.6, 0.30),
        ("bensound-scifi.mp3", 33, 146.8, 0.70),
        ("bensound-tomorrow.mp3", 44, 174.6, 0.54),
    ]
    for name, seed, base, tempo in tracks:
        p = os.path.join(out, name)
        if not os.path.exists(p):
            tone_mp3(p, seed, seconds=26, base=base, tempo=tempo)
            print("audio ->", name)

    print("Assets generados en", ASSETS)


if __name__ == "__main__":
    main()

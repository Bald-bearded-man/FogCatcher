"""Answer-key maps: real OSM map with numbered item markers plus a legend.

Usage (from the repo root):
  python3 tool/solution/make_solution_maps.py <out_dir> [tile_cache_dir]
Covers every site in assets/sites/index.json (heading = site name, zoom fitted to the radius).
Writes <site>-solution.png per site and solutions.pdf. Needs Pillow; OSM tiles are
fetched once (with a User-Agent) and cached. Never ship the output: it reveals every item.
"""
import json, math, os, sys, time, urllib.request
from PIL import Image, ImageDraw, ImageFont, ImageOps

if len(sys.argv) < 2:
    sys.exit(__doc__)
OUT = sys.argv[1]
CACHE = sys.argv[2] if len(sys.argv) > 2 else os.path.join(OUT, 'tiles')
APP = json.load(open('pack/pack.json'))['appName']
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
BOLD = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
BLUE, ORANGE, INK, PAPER = (91, 155, 213), (242, 101, 48), (55, 54, 59), (242, 242, 242)
os.makedirs(OUT, exist_ok=True); os.makedirs(CACHE, exist_ok=True)


WORDS = [('swimming_pool', 'Swimming pool'), ('sport=tennis', 'Tennis court'), ('sport=soccer', 'Football pitch'),
         ('tourism=information', 'Information point'), ('playground', 'Playground'), ('picnic', 'Picnic site'),
         ('restaurant', 'Restaurant'), ('cafe', 'Café'), ('bar', 'Bar'), ('memorial', 'Memorial'),
         ('place_of_worship', 'Chapel'), ('castle', 'Castle'), ('ruins', 'Ruins'), ('arts_centre', 'Arts centre'),
         ('post_box', 'Post box'), ('waste_basket', 'Litter bin'), ('shelter', 'Shelter'), ('historic', 'Historic site'),
         ('parking', 'Car park'), ('park', 'Park'), ('pitch', 'Sports pitch'),
         ('zone cell', 'Forest'), ('path cell', 'Footpath'), ('building', 'Building')]


def describe(landmark):
    # Seed landmarks hold raw OSM tags; keep the name part and turn tags into words.
    name = landmark.split(' · ')[0] if ' · ' in landmark else ''
    kind = next((w for k, w in WORDS if k in landmark), '')
    return ' · '.join(x for x in (name, kind) if x) or landmark


def font(size, bold=False):
    return ImageFont.truetype(BOLD if bold else FONT, size)


def tile_xy(lat, lng, z):
    n = 2 ** z
    return (lng + 180) / 360 * n, (1 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2 * n


def fetch(z, x, y):
    p = os.path.join(CACHE, f'{z}_{x}_{y}.png')
    if not os.path.exists(p):
        req = urllib.request.Request(f'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                     headers={'User-Agent': 'fogcatcher-solution/0.1'})
        open(p, 'wb').write(urllib.request.urlopen(req, timeout=30).read())
        time.sleep(0.3)  # be polite to the OSM tile servers
    return Image.open(p).convert('RGB')


def zoom_for(info, target_px=1400):
    # Largest zoom at which the play circle still fits in about target_px.
    m_per_px_z0 = 156543.03 * math.cos(math.radians(info['center']['lat']))
    z = math.floor(math.log2(target_px * m_per_px_z0 / (2 * info['radiusMeters'])))
    return max(14, min(19, z))


def render(site):
    info = json.load(open(f'assets/sites/{site}/site.json'))
    items = json.load(open(f'assets/sites/{site}/items.json'))['items']
    seed_path = f'tool/mapgen/seed/{site}.json'
    seed = {s['id']: s.get('landmark', '') for s in json.load(open(seed_path))['items']} if os.path.exists(seed_path) else {}
    z, heading = zoom_for(info), info['name']
    b = info['bounds']
    x0, y0 = tile_xy(b['north'], b['west'], z); x1, y1 = tile_xy(b['south'], b['east'], z)
    tx0, ty0, tx1, ty1 = int(x0), int(y0), int(x1), int(y1)
    m = Image.new('RGB', ((tx1 - tx0 + 1) * 256, (ty1 - ty0 + 1) * 256))
    for tx in range(tx0, tx1 + 1):
        for ty in range(ty0, ty1 + 1):
            m.paste(fetch(z, tx, ty), ((tx - tx0) * 256, (ty - ty0) * 256))
    m = m.crop((int((x0 - tx0) * 256), int((y0 - ty0) * 256), int((x1 - tx0) * 256), int((y1 - ty0) * 256)))
    px = lambda lat, lng: ((tile_xy(lat, lng, z)[0] - x0) * 256, (tile_xy(lat, lng, z)[1] - y0) * 256)
    mpp = 156543.03 * math.cos(math.radians(info['center']['lat'])) / 2 ** z
    d = ImageDraw.Draw(m)
    # Play-area circle for reference.
    cx, cy = px(info['center']['lat'], info['center']['lng']); r = info['radiusMeters'] / mpp
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=BLUE, width=4)
    f = font(22, True)
    for n, it in enumerate(items, 1):
        x, y = px(it['lat'], it['lng']); rr = it.get('radiusMeters', 20) / mpp
        d.ellipse((x - rr, y - rr, x + rr, y + rr), outline=ORANGE, width=3)
        d.ellipse((x - 17, y - 17, x + 17, y + 17), fill=ORANGE, outline=INK, width=3)
        d.text((x, y), str(n), font=f, fill='white', anchor='mm')
    # Legend panel with thumbnail, title, landmark and coordinates.
    row, thumb, lw = 92, 80, 900
    legend = Image.new('RGB', (lw, max(m.height, 140 + row * len(items))), PAPER)
    ld = ImageDraw.Draw(legend)
    ld.text((24, 24), f'{APP} — solution', font=font(34, True), fill=BLUE)
    ld.text((24, 70), heading, font=font(22), fill=INK)
    for n, it in enumerate(items, 1):
        top = 120 + (n - 1) * row
        ld.ellipse((24, top + 22, 60, top + 58), fill=ORANGE)
        ld.text((42, top + 40), str(n), font=font(20, True), fill='white', anchor='mm')
        im = ImageOps.fit(Image.open(it['image']).convert('RGB'), (thumb, thumb))
        legend.paste(im, (76, top + 4))
        ld.text((172, top + 6), f"{it['id']} · {it['title']}", font=font(22, True), fill=INK)
        ld.text((172, top + 36), describe(seed.get(it['id'], ''))[:70], font=font(17), fill=INK)
        ld.text((172, top + 60), f"{it['lat']:.6f}, {it['lng']:.6f}", font=font(17), fill=(110, 110, 110))
    out = Image.new('RGB', (m.width + lw, max(m.height, legend.height)), PAPER)
    out.paste(m, (0, 0)); out.paste(legend, (m.width, 0))
    ImageDraw.Draw(out).text((8, m.height - 26), '© OpenStreetMap contributors', font=font(16), fill=INK)
    path = os.path.join(OUT, f'{site}-solution.png'); out.save(path, optimize=True)
    return path, out


pages = []
for site in json.load(open('assets/sites/index.json'))['sites']:
    path, img = render(site); pages.append(img); print(path, img.size)
pdf = os.path.join(OUT, 'solutions.pdf')
pages[0].save(pdf, save_all=True, append_images=pages[1:], resolution=150)
print(pdf)

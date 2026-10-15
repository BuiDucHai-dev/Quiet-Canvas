"""Quiet Canvas UI kit: renders every app screen as HTML, then PNG via headless Chrome."""
import json, re, collections, subprocess, calendar, datetime, os

ROOT = "/Users/hai/Documents/MyIOS/Coloring-PaintTheNumber"
OUT = f"{ROOT}/.stitch/designs/ui"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
os.makedirs(OUT, exist_ok=True)

# ---------- artwork ----------
T = json.load(open(f"{ROOT}/Coloring-PaintTheNumber/Templates/001_normal_ocean_friends_1.json"))
PAL = {p["id"]: p["hex"] for p in T["palette"]}

def otter(fill_ratio=1.0, numbers=False, highlight=None, done_colors=(), stroke=1.1):
    out = []
    labels = []
    for r in T["regions"]:
        filled = r["color"] in done_colors or (r["color"] != highlight and (r["id"] * 37 % 100) / 100 < fill_ratio)
        if filled:
            f = PAL[r["color"]]
        elif r["color"] == highlight:
            f = "url(#hl)"
        else:
            f = "#fff"
        out.append(f'<path d="{r["path"]}" fill="{f}" fill-rule="evenodd" stroke="#9A948C" stroke-width="{stroke}"/>')
        if numbers and not filled and r["label"]["size"] >= 9:
            l = r["label"]
            labels.append(f'<text x="{l["x"]}" y="{l["y"]}" font-size="{l["size"]}">{r["color"]}</text>')
    defs = ('<defs><pattern id="hl" width="14" height="14" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">'
            '<rect width="14" height="14" fill="#fff"/><rect width="6" height="14" fill="#B4532F" fill-opacity=".22"/></pattern></defs>')
    return (f'<svg class="art" viewBox="0 0 {T["width"]} {T["height"]}" preserveAspectRatio="xMidYMid slice">'
            f'{defs}{"".join(out)}<g class="nums">{"".join(labels)}</g></svg>')

# simple flat illustrations from the Stitch library mockup (placeholders for real artwork)
_lib = open(f"{ROOT}/.stitch/designs/library.html").read()
_svgs = re.findall(r"<svg.*?</svg>", _lib, re.S)
NAMES = {"Ocean Friends": 0, "Sleeping Cat": 2, "Sunflower Field": 4, "Lighthouse Dawn": 6, "Cozy Reading Nook": 7,
         "Botanical Mandala": 8, "Single Peony": 9, "Teacup & Lemon": 10, "Sleeping Kitten": 11, "Spring Bouquet": 12,
         "Wildflower Meadow": 13, "Vintage Roses": 14, "Lavender Horizon": 15, "Golden Pup": 16, "Window Watcher": 17,
         "Calico Nap": 18}

def art(name):
    if name == "Ocean Friends":
        return otter(1.0)
    s = _svgs[NAMES[name]]
    m = re.search(r"bg-\[(#\w+)\]", s)
    bg = m.group(1) if m else "#FFFFFF"
    s = re.sub(r'<svg[^>]*?viewbox="([^"]+)"[^>]*>', lambda m: f'<svg class="art" viewBox="{m.group(1)}" style="background:{bg}">', s, count=1)
    return s

# ---------- icons (stand-ins for SF Symbols) ----------
P = {
    "books": '<path d="M4 4h4v16H4zM10 4h4v16h-4zM15.6 5.2l3.7-.9 3.2 15.4-3.7.9z"/>',
    "flame": '<path d="M12 2.5c1.2 3.2 5.5 5.3 5.5 10.5a5.5 5.5 0 0 1-11 0c0-2.3 1.1-3.9 2.2-5 .3 1.6 1.1 2.7 2.2 3.2-.2-3.2-.6-5.6 1.1-8.7z"/>',
    "photos": '<rect x="3" y="6.5" width="14" height="14" rx="2.5"/><path d="M7 3.5h11.5a2.5 2.5 0 0 1 2.5 2.5v11.5"/><path d="M3.5 17l4-4 4 4 2-2 3.5 3.5"/>',
    "gear": '<circle cx="12" cy="12" r="3.2"/><path d="M12 3.2l1.5 2.3 2.6-.8.6 2.7 2.7.6-.8 2.6 2.3 1.4-2.3 1.4.8 2.6-2.7.6-.6 2.7-2.6-.8-1.5 2.3-1.5-2.3-2.6.8-.6-2.7-2.7-.6.8-2.6L3.2 12l2.3-1.4-.8-2.6 2.7-.6.6-2.7 2.6.8z"/>',
    "lock": '<rect x="5" y="10.5" width="14" height="10.5" rx="2.5" fill="currentColor"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5"/>',
    "check": '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    "left": '<path d="M15 4l-8 8 8 8"/>',
    "right": '<path d="M9 4l8 8-8 8"/>',
    "crown": '<path d="M3 8l4.5 4L12 5l4.5 7L21 8l-2 11H5z" fill="currentColor"/>',
    "share": '<path d="M12 3v12M8 7l4-4 4 4M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7"/>',
    "save": '<path d="M12 4v11M8 11l4 4 4-4M5 20h14"/>',
    "x": '<path d="M6 6l12 12M18 6L6 18"/>',
    "calendar": '<rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M3 10h18M8 3v4M16 3v4"/>',
    "bulb": '<path d="M12 2.5a6.5 6.5 0 0 0-3.9 11.7c.7.5 1.1 1.3 1.1 2.1V17h5.6v-.7c0-.8.4-1.6 1.1-2.1A6.5 6.5 0 0 0 12 2.5zM9.5 20.5h5"/>',
    "dots": '<circle cx="5" cy="12" r="1.6" fill="currentColor"/><circle cx="12" cy="12" r="1.6" fill="currentColor"/><circle cx="19" cy="12" r="1.6" fill="currentColor"/>',
    "bell": '<path d="M6 16.5V11a6 6 0 0 1 12 0v5.5l1.8 1.8H4.2zM10 21h4"/>',
    "sparkle": '<path d="M12 3l1.8 5.4L19 10l-5.2 1.6L12 17l-1.8-5.4L5 10l5.2-1.6z" fill="currentColor"/>',
    "leaf": '<path d="M5 19c0-8 5-14 15-14 0 9-6 14-13 14M5 19l7-7"/>',
    "heart": '<path d="M12 20s-7.5-4.6-7.5-10A4.3 4.3 0 0 1 12 7.4 4.3 4.3 0 0 1 19.5 10C19.5 15.4 12 20 12 20z"/>',
    "reset": '<path d="M4 12a8 8 0 1 0 2.4-5.7M4 4v4.5h4.5"/>',
    "star": '<path d="M12 3.5l2.6 5.3 5.8.8-4.2 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8-4.2-4.1 5.8-.8z"/>',
    "mail": '<rect x="3" y="5.5" width="18" height="13" rx="2.5"/><path d="M3.5 7l8.5 6 8.5-6"/>',
    "doc": '<path d="M6 3h8l4 4v14H6zM14 3v4h4M9 12h6M9 16h6"/>',
    "text": '<path d="M5 6h14M12 6v13M8.5 19h7"/>',
    "hand": '<path d="M8 13V5.5a1.5 1.5 0 0 1 3 0V11m0-4.5a1.5 1.5 0 0 1 3 0V11m0-3a1.5 1.5 0 0 1 3 0v6c0 4-2.5 7-6.5 7-2.6 0-4-1.2-5.4-3.2L3.8 14a1.5 1.5 0 0 1 2.4-1.8L8 14"/>',
    "trash": '<path d="M4 7h16M9 7V4h6v3M6.5 7l1 13h9l1-13"/>',
}

def ic(name, size=24, color="currentColor", sw=1.8):
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="{color}" stroke-width="{sw}" '
            f'stroke-linecap="round" stroke-linejoin="round" style="color:{color};flex:none">{P[name]}</svg>')

# ---------- shared CSS ----------
CSS = """
:root{--paper:#FAF6F0;--well:#F1ECE4;--surface:#FFFFFF;--ink:#2B2622;--ink2:#6B625A;--ink3:#9A918A;
--accent:#B4532F;--accent-soft:#F6E3DA;--success:#4E8B5F;--line:#E8E1D7;--flame:#E07B39;--shadow:0 2px 8px rgba(43,38,34,.07)}
*{box-sizing:border-box;margin:0;padding:0}
html,body{width:402px;height:874px;overflow:hidden}
body{background:var(--paper);font-family:-apple-system,system-ui,sans-serif;color:var(--ink);font-size:17px;position:relative}
.serif{font-family:ui-serif,'New York',Georgia,serif}
.round{font-family:ui-rounded,-apple-system,sans-serif}
.status{height:54px;display:flex;align-items:center;justify-content:space-between;padding:0 30px 0 34px;font-weight:600;font-size:17px;position:relative;z-index:5}
.island{position:absolute;left:50%;top:11px;transform:translateX(-50%);width:124px;height:36px;background:#000;border-radius:20px}
.sys{display:flex;gap:6px;align-items:center}
.sys i{display:block;width:4px;background:var(--ink);border-radius:1px}
.batt{width:26px;height:12px;border:1.5px solid var(--ink);border-radius:4px;padding:1.5px}.batt b{display:block;height:100%;width:80%;background:var(--ink);border-radius:1.5px}
.home{position:absolute;bottom:8px;left:50%;transform:translateX(-50%);width:140px;height:5px;border-radius:3px;background:var(--ink);z-index:20}
.scroll{position:absolute;top:54px;left:0;right:0;bottom:0;overflow:hidden}
.pad{padding:0 20px}
h1{font-family:ui-serif,'New York',Georgia,serif;font-weight:600;font-size:34px;letter-spacing:-.4px;line-height:1.12}
h2{font-family:ui-serif,'New York',Georgia,serif;font-weight:600;font-size:22px;letter-spacing:-.2px}
.eyebrow{font-size:13px;letter-spacing:.9px;text-transform:uppercase;color:var(--ink2);font-weight:500}
.sub{font-size:15px;color:var(--ink2);line-height:1.4}
.cap{font-size:13px;color:var(--ink2)}
.link{font-size:15px;color:var(--accent);font-weight:500}
.sec{margin-top:30px}
.sec-h{display:flex;align-items:baseline;justify-content:space-between;padding:0 20px;margin-bottom:12px}
.row{display:flex;gap:14px;padding:0 20px;overflow:hidden}
.card{background:var(--surface);border-radius:20px;box-shadow:var(--shadow)}
.thumb{position:relative;border-radius:16px;overflow:hidden;background:#fff;box-shadow:var(--shadow);border:4px solid #fff}
.thumb .art{display:block;width:100%;height:100%;border-radius:12px}
.thumb .art .nums{display:none}
.tcap{font-size:15px;font-weight:500;margin-top:8px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.meta{display:flex;align-items:center;gap:6px;font-size:13px;color:var(--ink2);margin-top:3px}
.dots{display:flex;gap:3px}.dots b{width:6px;height:6px;border-radius:3px;background:var(--line)}.dots b.on{background:var(--accent)}
.badge{position:absolute;z-index:2}
.pill{display:inline-flex;align-items:center;gap:4px;font-size:11px;font-weight:700;letter-spacing:.5px;padding:3px 8px;border-radius:10px;background:var(--accent);color:#fff}
.lockb{top:8px;right:8px;width:28px;height:28px;border-radius:14px;background:rgba(255,255,255,.92);display:flex;align-items:center;justify-content:center;box-shadow:var(--shadow)}
.doneb{top:8px;right:8px;width:28px;height:28px;border-radius:14px;background:var(--success);display:flex;align-items:center;justify-content:center}
.ring{top:8px;right:8px;width:36px;height:36px;border-radius:18px;background:rgba(255,255,255,.95);display:flex;align-items:center;justify-content:center;box-shadow:var(--shadow)}
.ring span{position:absolute;font-size:10px;font-weight:700}
.btn{display:flex;align-items:center;justify-content:center;gap:8px;height:54px;border-radius:27px;font-size:17px;font-weight:600}
.btn.primary{background:var(--accent);color:#fff}
.btn.secondary{background:var(--surface);color:var(--ink);box-shadow:var(--shadow);border:1px solid var(--line)}
.ibtn{width:44px;height:44px;border-radius:22px;background:var(--surface);box-shadow:var(--shadow);display:flex;align-items:center;justify-content:center;flex:none}
.tabbar{position:absolute;left:0;right:0;bottom:0;height:88px;background:rgba(250,246,240,.97);border-top:1px solid var(--line);display:flex;justify-content:space-around;padding-top:8px;z-index:10}
.tab{display:flex;flex-direction:column;align-items:center;gap:3px;font-size:11px;font-weight:500;color:var(--ink3);width:100px;position:relative}
.tab.on{color:var(--accent)}
.tab .dot{position:absolute;top:-1px;left:58px;width:9px;height:9px;border-radius:5px;background:#D9452B;border:2px solid var(--paper)}
.seg{display:flex;background:var(--well);border-radius:12px;padding:3px;gap:3px}
.seg div{flex:1;text-align:center;font-size:15px;font-weight:500;padding:8px 0;border-radius:9px;color:var(--ink2)}
.seg .on{background:var(--surface);color:var(--ink);box-shadow:var(--shadow);font-weight:600}
.chips{display:flex;gap:8px}
.chip{padding:8px 16px;border-radius:18px;font-size:15px;font-weight:500;background:var(--surface);border:1px solid var(--line);color:var(--ink2)}
.chip.on{background:var(--ink);color:#fff;border-color:var(--ink)}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:18px 14px;padding:0 20px}
.grid .thumb{aspect-ratio:1}
.scrim{position:absolute;inset:0;background:rgba(43,38,34,.42);z-index:30}
.sheet{position:absolute;left:0;right:0;bottom:0;background:var(--paper);border-radius:28px 28px 0 0;z-index:31;padding:10px 20px 40px}
.grab{width:40px;height:5px;border-radius:3px;background:var(--line);margin:0 auto 14px}
.list{background:var(--surface);border-radius:14px;overflow:hidden}
.li{display:flex;align-items:center;gap:12px;padding:0 16px;min-height:50px;border-bottom:1px solid var(--line);font-size:17px}
.li:last-child{border-bottom:none}
.li .ico{width:30px;height:30px;border-radius:8px;display:flex;align-items:center;justify-content:center}
.li .val{margin-left:auto;color:var(--ink2);font-size:17px;display:flex;align-items:center;gap:6px}
.toggle{margin-left:auto;width:51px;height:31px;border-radius:16px;background:var(--success);position:relative}
.toggle:after{content:"";position:absolute;right:2px;top:2px;width:27px;height:27px;border-radius:14px;background:#fff;box-shadow:0 2px 4px rgba(0,0,0,.15)}
.toggle.off{background:#E3DDD3}.toggle.off:after{right:auto;left:2px}
.grp-h{font-size:13px;text-transform:uppercase;letter-spacing:.6px;color:var(--ink2);margin:24px 16px 8px}
.paper-sheet text{font-family:ui-rounded,-apple-system,sans-serif;font-weight:600;fill:rgba(43,38,34,.72);text-anchor:middle;dominant-baseline:central}
"""

def status(dark=False):
    bars = "".join(f'<i style="height:{h}px"></i>' for h in (4, 6, 8, 10))
    return (f'<div class="status"><span>9:41</span><div class="island"></div>'
            f'<div class="sys">{bars}<div class="batt"><b></b></div></div></div>')

def bg(name):
    body = re.search(r"<body>(.*)</body>", S[name], re.S).group(1)
    return re.sub(r'<div class="status">.*?</div></div></div>', '', body, count=1, flags=re.S).replace('<div class="home"></div>', '')

def page(body, tab=None):
    tb = ""
    if tab:
        items = [("books", "Library"), ("flame", "Challenges"), ("photos", "My Works")]
        cells = []
        for name, label in items:
            on = label == tab
            dot = '<div class="dot"></div>' if label == "Challenges" and tab != "Challenges" else ""
            cells.append(f'<div class="tab{" on" if on else ""}">{dot}{ic(name, 26, "#B4532F" if on else "#9A918A", 2 if on else 1.7)}{label}</div>')
        tb = f'<div class="tabbar">{"".join(cells)}</div>'
    return (f'<!doctype html><html><head><meta charset="utf-8"><style>{CSS}</style></head>'
            f'<body>{status()}{body}{tb}<div class="home"></div></body></html>')

def dots(n):
    return '<div class="dots">' + "".join(f'<b class="{"on" if i < n else ""}"></b>' for i in range(3)) + "</div>"

LEVEL = {1: "Easy", 2: "Medium", 3: "Hard"}

def thumb(name, size=150, level=None, badge=None, sub=None, art_html=None, caption=True):
    b = ""
    if badge == "new":
        b = '<div class="badge" style="top:8px;left:8px"><span class="pill">NEW</span></div>'
    elif badge == "lock":
        b = f'<div class="badge lockb">{ic("lock", 15, "#6B625A", 1.8)}</div>'
    elif badge == "done":
        b = f'<div class="badge doneb">{ic("check", 16, "#fff", 2.6)}</div>'
    elif isinstance(badge, int):
        c = 2 * 3.1416 * 14
        b = (f'<div class="badge ring"><svg width="32" height="32" viewBox="0 0 32 32"><circle cx="16" cy="16" r="14" fill="none" stroke="#E8E1D7" stroke-width="3"/>'
             f'<circle cx="16" cy="16" r="14" fill="none" stroke="#B4532F" stroke-width="3" stroke-linecap="round" stroke-dasharray="{c * badge / 100:.1f} {c:.1f}" transform="rotate(-90 16 16)"/></svg><span>{badge}%</span></div>')
    meta = ""
    if level:
        meta = f'<div class="meta">{dots(level)}{LEVEL[level]}</div>'
    if sub:
        meta = f'<div class="meta">{sub}</div>'
    cap = f'<div class="tcap">{name}</div>{meta}' if caption else ""
    w = f"width:{size}px;" if size else ""
    h = f"height:{size}px;" if size else ""
    return f'<div style="{w}flex:none"><div class="thumb" style="{h}">{b}{art_html or art(name)}</div>{cap}</div>'

# ---------- screens ----------
S = {}

S["01_welcome"] = page(f"""
<div class="pad" style="padding-top:40px;text-align:center">
  <div class="eyebrow">Quiet Canvas</div>
  <div class="thumb" style="width:300px;height:300px;margin:28px auto 0;border-width:8px;border-radius:24px">{otter(1.0)}</div>
  <h1 style="margin-top:34px">Color your calm</h1>
  <p class="sub" style="font-size:17px;margin:12px 16px 0">Tap a number, fill a shape, and watch a picture come to life. No skill needed.</p>
</div>
<div class="pad" style="position:absolute;left:0;right:0;bottom:56px">
  <div class="btn primary">Get started</div>
  <p class="cap" style="text-align:center;margin-top:16px">Already a member? <span class="link" style="font-size:13px">Restore purchase</span></p>
</div>""")

themes = [("Flowers", "Spring Bouquet", True), ("Cats & Dogs", "Golden Pup", True), ("Ocean", "Ocean Friends", False),
          ("Cozy Home", "Cozy Reading Nook", True), ("Mandala", "Botanical Mandala", False), ("Nature", "Wildflower Meadow", False),
          ("Faith", "Lighthouse Dawn", False), ("Holidays", "Teacup & Lemon", False)]
cells = ""
for label, a, on in themes:
    chk = (f'<div class="badge" style="top:8px;right:8px;width:28px;height:28px;border-radius:14px;background:{"#B4532F" if on else "rgba(255,255,255,.9)"};'
           f'border:{"none" if on else "1.5px solid #E8E1D7"};display:flex;align-items:center;justify-content:center">{ic("check", 16, "#fff", 2.6) if on else ""}</div>')
    ring = "box-shadow:0 0 0 3px #B4532F;" if on else ""
    cells += f'<div><div class="thumb" style="height:118px;{ring}">{chk}{art(a)}</div><div class="tcap" style="text-align:center">{label}</div></div>'
S["02_themes"] = page(f"""
<div class="pad" style="padding-top:12px">
  <div style="display:flex;gap:6px;margin-bottom:22px"><b style="flex:1;height:4px;border-radius:2px;background:#B4532F"></b><b style="flex:1;height:4px;border-radius:2px;background:#B4532F"></b><b style="flex:1;height:4px;border-radius:2px;background:#E8E1D7"></b></div>
  <h1 style="font-size:30px">What do you love to color?</h1>
  <p class="sub" style="margin-top:8px">Pick a few. We'll put them first in your library.</p>
</div>
<div class="grid" style="margin-top:22px;gap:14px 14px;grid-template-columns:1fr 1fr">{cells}</div>
<div class="pad" style="position:absolute;left:0;right:0;bottom:44px;background:linear-gradient(transparent,var(--paper) 30%);padding-top:30px">
  <div class="btn primary">Continue · 3 selected</div>
</div>""")

coll = "".join(f'<div class="thumb" style="width:150px;height:150px;transform:rotate({r}deg);position:absolute;left:{x}px;top:{y}px">{art(n)}</div>'
               for n, r, x, y in [("Spring Bouquet", -6, 20, 20), ("Ocean Friends", 4, 196, 6), ("Golden Pup", 5, 40, 150), ("Cozy Reading Nook", -4, 190, 150)])
perks = [("sparkle", "Every picture, all themes", "96 pictures today, new ones every week"),
         ("calendar", "Every past challenge", "Paint any day you missed"),
         ("heart", "No ads, ever", "Just you and your canvas")]
perk_html = "".join(f'<div style="display:flex;gap:14px;align-items:flex-start;margin-top:16px"><div style="width:36px;height:36px;border-radius:18px;background:var(--accent-soft);display:flex;align-items:center;justify-content:center;flex:none">{ic(i, 20, "#B4532F")}</div><div><div style="font-weight:600;font-size:17px">{t}</div><div class="cap" style="margin-top:2px">{d}</div></div></div>' for i, t, d in perks)
S["03_paywall"] = page(f"""
<div class="ibtn" style="position:absolute;top:58px;right:20px;z-index:6;box-shadow:none;background:var(--well)">{ic("x", 18, "#6B625A", 2.2)}</div>
<div style="position:relative;height:300px;margin-top:10px">{coll}</div>
<div class="pad">
  <h1 style="font-size:30px;text-align:center">Unlock every picture</h1>
  {perk_html}
  <div style="margin-top:22px;display:flex;flex-direction:column;gap:10px">
    <div class="card" style="padding:14px 16px;border:2px solid #B4532F;display:flex;align-items:center;gap:12px;position:relative">
      <span class="pill" style="position:absolute;top:-11px;right:16px">BEST VALUE</span>
      <div style="width:22px;height:22px;border-radius:11px;background:#B4532F;display:flex;align-items:center;justify-content:center">{ic("check", 14, "#fff", 3)}</div>
      <div style="flex:1"><div style="font-weight:600">Yearly</div><div class="cap">7 days free, then $29.99/year</div></div>
      <div style="text-align:right"><div style="font-weight:600">$2.50</div><div class="cap">per month</div></div>
    </div>
    <div class="card" style="padding:14px 16px;border:1px solid #E8E1D7;display:flex;align-items:center;gap:12px;box-shadow:none">
      <div style="width:22px;height:22px;border-radius:11px;border:1.5px solid #C9C0B5"></div>
      <div style="flex:1"><div style="font-weight:600">Weekly</div><div class="cap">No free trial</div></div>
      <div style="font-weight:600">$4.99</div>
    </div>
  </div>
  <div class="btn primary" style="margin-top:18px">Start my free week</div>
  <p class="cap" style="text-align:center;margin-top:12px;font-size:12px">Cancel anytime in Settings. &nbsp;Restore · Terms · Privacy</p>
</div>""")

S["04_library"] = page(f"""
<div class="scroll" style="bottom:88px">
  <div class="pad" style="display:flex;align-items:flex-end;justify-content:space-between;padding-top:8px">
    <div><div class="eyebrow">Quiet Canvas</div><h1 style="margin-top:4px">Good evening</h1></div>
    <div class="ibtn">{ic("gear", 22, "#2B2622", 1.6)}</div>
  </div>
  <div class="pad" style="margin-top:18px"><div class="card" style="display:flex;align-items:center;gap:12px;padding:12px 14px">
    <div style="width:36px;height:36px;border-radius:18px;background:var(--accent-soft);display:flex;align-items:center;justify-content:center">{ic("crown", 18, "#B4532F", 1.2)}</div>
    <div style="flex:1"><div style="font-weight:600;font-size:16px">Unlock 80+ pictures</div><div class="cap">Try Premium free for 7 days</div></div>{ic("right", 16, "#9A918A", 2)}
  </div></div>
  <div class="sec"><div class="sec-h"><h2>Continue painting</h2><span class="cap">3 in progress</span></div>
    <div class="row">{thumb("Ocean Friends", 150, badge=45, art_html=otter(.45))}{thumb("Sleeping Cat", 150, badge=12)}{thumb("Sunflower Field", 150, badge=80)}</div></div>
  <div class="sec"><div class="sec-h"><h2>New this week</h2><span class="link">See all</span></div>
    <div class="row">{thumb("Lighthouse Dawn", 150, 2, "new")}{thumb("Cozy Reading Nook", 150, 1, "new")}{thumb("Botanical Mandala", 150, 3, "new")}</div></div>
  <div class="sec"><div class="sec-h"><h2>Flowers</h2><span class="link">See all</span></div>
    <div class="row">{thumb("Spring Bouquet", 150, 1)}{thumb("Wildflower Meadow", 150, 2)}{thumb("Vintage Roses", 150, 2, "lock")}</div></div>
</div>""", tab="Library")

tg = [("Spring Bouquet", 1, None), ("Single Peony", 1, "done"), ("Wildflower Meadow", 2, 30), ("Vintage Roses", 2, "lock"),
      ("Lavender Horizon", 3, "lock"), ("Sunflower Field", 2, "lock")]
S["05_theme"] = page(f"""
<div class="pad" style="display:flex;align-items:center;gap:12px;padding-top:6px">
  <div class="ibtn">{ic("left", 20, "#2B2622", 2.2)}</div><div style="flex:1"></div>
</div>
<div class="pad" style="margin-top:10px"><h1>Flowers</h1><p class="sub" style="margin-top:4px">12 pictures · 2 free</p></div>
<div class="pad" style="margin-top:16px"><div class="chips"><div class="chip on">All</div><div class="chip">Easy</div><div class="chip">Medium</div><div class="chip">Hard</div></div></div>
<div class="grid" style="margin-top:18px">{"".join(thumb(n, None, l, b) for n, l, b in tg)}</div>""", tab="Library")

S["06_preview"] = page(f"""
<div style="opacity:1">{bg("05_theme")}</div>
<div class="scrim"></div>
<div class="sheet">
  <div class="grab"></div>
  <div class="thumb" style="width:300px;height:300px;margin:0 auto;border-width:6px;border-radius:22px">{art("Vintage Roses")}</div>
  <h2 style="text-align:center;margin-top:20px;font-size:26px">Vintage Roses</h2>
  <div class="meta" style="justify-content:center;margin-top:6px;font-size:15px">{dots(2)} Medium · 142 shapes · 18 colors · about 30 min</div>
  <div class="btn primary" style="margin-top:22px">{ic("crown", 18, "#fff", 1.2)} Unlock with Premium</div>
  <p style="text-align:center;margin-top:16px" class="link">Try today's free challenge instead</p>
</div>""")

S["07_paint"] = page(f"""
<div style="display:flex;align-items:center;gap:8px;padding:4px 16px 12px;border-bottom:1px solid var(--line)">
  <div class="ibtn">{ic("left", 20, "#2B2622", 2.2)}</div>
  <div style="flex:1;text-align:center"><div class="serif" style="font-size:19px;font-weight:600">Ocean Friends</div>
    <div style="height:4px;border-radius:2px;background:var(--line);margin:6px 30px 4px;overflow:hidden"><i style="display:block;height:100%;width:43%;background:var(--accent)"></i></div>
    <div class="cap">54 of 127</div></div>
  <div class="ibtn">{ic("bulb", 22, "#B4532F", 1.8)}</div><div class="ibtn">{ic("dots", 22, "#2B2622")}</div>
</div>
<div style="position:absolute;top:135px;bottom:122px;left:0;right:0;background:var(--well);display:flex;align-items:center;justify-content:center">
  <div class="paper-sheet" style="width:370px;height:370px;background:#fff;border-radius:6px;box-shadow:0 2px 12px rgba(0,0,0,.08);overflow:hidden">{otter(.5, True, 17, (1, 3))}</div>
</div>
<div style="position:absolute;left:0;right:0;bottom:0;height:122px;border-top:1px solid var(--line);padding-top:14px;overflow:hidden">
  <div style="display:flex;gap:12px;padding:0 20px;transform:translateX(-952px);width:max-content">
  {"".join(f'<div style="width:56px;display:flex;flex-direction:column;align-items:center"><div class="round" style="width:52px;height:52px;border-radius:26px;background:{PAL[i]};display:flex;align-items:center;justify-content:center;font-weight:700;font-size:19px;color:{"#2B2622" if i > 13 else "#fff"};box-shadow:inset 0 0 0 1px rgba(0,0,0,.12){",0 0 0 3px #FAF6F0,0 0 0 6px #B4532F" if i == 17 else ""}">{i}</div>{"<div style=&quot;font-size:12px;font-weight:600;color:#B4532F;margin-top:8px&quot;>27 left</div>".replace("&quot;", chr(34)) if i == 17 else ""}</div>' for i in sorted(PAL))}
  </div>
</div>""")

S["08_complete"] = page(f"""
<div class="pad" style="padding-top:10px;text-align:center">
  <div style="display:inline-flex;align-items:center;gap:6px;background:#FCEBDD;color:#B4532F;font-weight:600;font-size:15px;padding:7px 14px;border-radius:18px">{ic("flame", 16, "#E07B39", 2)} 6 day streak</div>
  <h1 style="margin-top:14px">Beautiful work</h1>
  <p class="sub" style="margin-top:6px">Ocean Friends · 127 shapes · 24 minutes</p>
  <div class="thumb" style="width:330px;height:330px;margin:22px auto 0;border-width:8px;border-radius:24px">{otter(1.0)}</div>
  <div style="display:flex;gap:12px;margin-top:22px">
    <div class="btn primary" style="flex:1">{ic("share", 20, "#fff", 2)} Share</div>
    <div class="btn secondary" style="flex:1">{ic("save", 20, "#2B2622", 2)} Save</div>
  </div>
</div>
<div class="sec" style="margin-top:28px"><div class="sec-h"><h2 style="font-size:20px">Paint another</h2><span class="link">Library</span></div>
  <div class="row">{thumb("Lighthouse Dawn", 112, 2)}{thumb("Golden Pup", 112, 1)}{thumb("Vintage Roses", 112, 2, "lock")}</div></div>""")

# challenges calendar: October 2026
cal = calendar.Calendar(firstweekday=6).monthdayscalendar(2026, 10)
state = {1: "done", 2: "miss", 3: "done", 4: "rest", 5: "done", 6: "done", 7: "done", 8: "today"}
cal_art = ["Single Peony", "Teacup & Lemon", "Sleeping Kitten", "Golden Pup", "Spring Bouquet", "Calico Nap", "Window Watcher"]
cells, k = "", 0
for week in cal:
    for d in week:
        st = state.get(d)
        inner, style = f'<span class="cap">{d or ""}</span>', ""
        if st == "done":
            inner = f'<div style="width:38px;height:38px;border-radius:10px;overflow:hidden;border:2px solid #fff;box-shadow:var(--shadow)">{art(cal_art[k % 7])}</div>'
            k += 1
        elif st == "miss":
            inner = f'<div style="width:38px;height:38px;border-radius:10px;background:var(--well);display:flex;align-items:center;justify-content:center">{ic("lock", 14, "#9A918A")}</div>'
        elif st == "rest":
            inner = f'<div style="width:38px;height:38px;border-radius:10px;border:1.5px dashed #C9C0B5;display:flex;align-items:center;justify-content:center;font-size:11px;color:var(--ink2)">rest</div>'
        elif st == "today":
            inner = f'<div style="width:38px;height:38px;border-radius:19px;border:2px solid #B4532F;display:flex;align-items:center;justify-content:center;font-weight:700;color:#B4532F">{d}</div>'
        cells += f'<div style="height:46px;display:flex;align-items:center;justify-content:center">{inner}</div>'
week_dots = "".join(f'<div style="display:flex;flex-direction:column;align-items:center;gap:6px"><div style="width:30px;height:30px;border-radius:15px;display:flex;align-items:center;justify-content:center;{s}">{c}</div><span class="cap" style="font-size:12px">{l}</span></div>'
                    for l, s, c in [("S", "border:1.5px dashed #C9C0B5", "<span style='font-size:9px;color:#6B625A'>rest</span>"), ("M", "background:#E07B39", ic("check", 14, "#fff", 3)),
                                    ("T", "background:#E07B39", ic("check", 14, "#fff", 3)), ("W", "background:#E07B39", ic("check", 14, "#fff", 3)),
                                    ("T", "border:2px solid #B4532F", ""), ("F", "background:var(--well)", ""), ("S", "background:var(--well)", "")])
S["09_challenges"] = page(f"""
<div class="scroll" style="bottom:88px">
  <div class="pad" style="padding-top:8px"><h1>Challenges</h1></div>
  <div class="pad" style="margin-top:16px"><div class="card" style="padding:14px;display:flex;gap:14px;align-items:center">
    <div class="thumb" style="width:132px;height:132px;flex:none;box-shadow:none;border-width:0">{art("Sleeping Kitten")}</div>
    <div style="flex:1"><div class="eyebrow" style="color:var(--accent)">Today · Oct 8</div>
      <div class="serif" style="font-size:22px;font-weight:600;margin-top:4px">Sleeping Kitten</div>
      <div class="meta">{dots(1)} Easy · 10 min</div>
      <div class="btn primary" style="height:44px;margin-top:12px;font-size:16px">Start painting</div></div>
  </div></div>
  <div class="pad" style="margin-top:14px"><div class="card" style="padding:16px">
    <div style="display:flex;align-items:center;gap:10px">{ic("flame", 30, "#E07B39", 2)}<div style="flex:1"><div style="font-weight:700;font-size:20px">5 day streak</div><div class="cap">Best 12 · 1 rest day left this week</div></div></div>
    <div style="display:flex;justify-content:space-between;margin-top:14px">{week_dots}</div>
  </div></div>
  <div class="pad" style="margin-top:22px;display:flex;justify-content:space-between;align-items:baseline"><h2>October</h2><span class="cap">5 of 7 days</span></div>
  <div class="pad" style="margin-top:10px"><div class="card" style="padding:10px 8px">
    <div style="display:grid;grid-template-columns:repeat(7,1fr);text-align:center" class="cap">{"".join(f"<div style='padding:4px 0'>{d}</div>" for d in "SMTWTFS")}</div>
    <div style="display:grid;grid-template-columns:repeat(7,1fr)">{cells}</div>
  </div></div>
</div>""", tab="Challenges")

works = [("Ocean Friends", 45, otter(.45)), ("Sleeping Cat", 12, None), ("Sunflower Field", 80, None), ("Window Watcher", 5, None)]
S["10_myworks"] = page(f"""
<div class="pad" style="padding-top:8px"><h1>My Works</h1></div>
<div class="pad" style="margin-top:14px"><div class="seg"><div class="on">In progress · 4</div><div>Completed · 9</div></div></div>
<div class="grid" style="margin-top:18px">{"".join(thumb(n, None, sub=f"{p}% · edited {d}", badge=p, art_html=a) for (n, p, a), d in zip(works, ["today", "yesterday", "Oct 5", "Oct 2"]))}</div>
<p class="cap" style="text-align:center;margin-top:18px">Long-press a picture to restart it</p>""", tab="My Works")

def li(icon, bg, label, val="", toggle=None, color="#fff"):
    right = f'<div class="toggle{"" if toggle else " off"}"></div>' if toggle is not None else f'<div class="val">{val}{ic("right", 14, "#C9C0B5", 2)}</div>'
    return f'<div class="li"><div class="ico" style="background:{bg}">{ic(icon, 18, color, 2)}</div>{label}{right}</div>'

lib_bg = bg("04_library")
S["11_settings"] = page(f"""
{lib_bg}<div class="scrim"></div>
<div class="sheet" style="top:64px;padding:10px 16px 0;background:#F4EFE8">
  <div class="grab"></div>
  <div style="display:flex;align-items:center;justify-content:space-between;padding:0 4px"><h2 style="font-size:26px">Settings</h2><span class="link" style="font-weight:600">Done</span></div>
  <div class="card" style="margin-top:16px;padding:16px;display:flex;gap:12px;align-items:center;background:var(--accent);color:#fff">
    {ic("crown", 26, "#fff", 1.2)}<div style="flex:1"><div style="font-weight:600">Quiet Canvas Premium</div><div style="font-size:13px;opacity:.85">All pictures and past challenges</div></div>
    <div style="background:#fff;color:#B4532F;font-weight:600;font-size:15px;padding:8px 14px;border-radius:16px">Try free</div>
  </div>
  <div class="grp-h" style="margin-top:18px">Painting</div>
  <div class="list">{li("text", "#B4532F", "Number size", "Large")}{li("sparkle", "#E0A43A", "Highlight matching shapes", toggle=True)}{li("right", "#4E8B5F", "Auto-pick next color", toggle=True)}{li("hand", "#7A6FB0", "Vibrate on fill", toggle=False)}</div>
  <div class="grp-h">Challenges</div>
  <div class="list">{li("bell", "#E07B39", "Daily reminder", toggle=True)}{li("calendar", "#6B625A", "Reminder time", "8:00 PM")}</div>
  <div class="grp-h">Support</div>
  <div class="list">{li("mail", "#4A7DB0", "Send feedback")}{li("star", "#E0A43A", "Rate Quiet Canvas")}{li("doc", "#9A918A", "Privacy & Terms")}</div>
  <div class="grp-h">Account</div>
  <div class="list">{li("reset", "#4A7DB0", "Restore purchases")}<div class="li"><div class="ico" style="background:#C2453A">{ic("trash", 18, "#fff", 2)}</div><span style="color:#C2453A">Reset all progress</span></div></div>
</div>""")

# ---------- render ----------
for name, html in S.items():
    path = f"{OUT}/{name}.html"
    open(path, "w").write(html)
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=2",
                    "--window-size=402,874", "--virtual-time-budget=3000", f"--screenshot={OUT}/{name}.png", f"file://{path}"],
                   stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)

# overview board
groups = [("Onboarding", ["01_welcome", "02_themes", "03_paywall"]),
          ("Library", ["04_library", "05_theme", "06_preview"]),
          ("Painting", ["07_paint", "08_complete"]),
          ("Tabs & settings", ["09_challenges", "10_myworks", "11_settings"])]
labels = {"01_welcome": "Welcome", "02_themes": "Pick themes", "03_paywall": "Paywall", "04_library": "Library",
          "05_theme": "Theme · See all", "06_preview": "Locked preview", "07_paint": "Painting", "08_complete": "Completed",
          "09_challenges": "Challenges", "10_myworks": "My Works", "11_settings": "Settings sheet"}
rows = ""
for g, items in groups:
    figs = "".join(f'<figure><img src="{i}.png"><figcaption>{labels[i]}</figcaption></figure>' for i in items)
    rows += f'<section><h3>{g}</h3><div class="r">{figs}</div></section>'
board = f"""<!doctype html><html><head><meta charset="utf-8"><style>
body{{margin:0;background:#EFE9E0;font-family:-apple-system,sans-serif;padding:60px 70px;width:1294px}}
h1{{font-family:ui-serif,Georgia,serif;font-size:56px;color:#2B2622;margin:0}}
.lead{{color:#6B625A;font-size:22px;margin:10px 0 30px}}
section{{margin-top:40px}} h3{{font-size:20px;letter-spacing:1.5px;text-transform:uppercase;color:#B4532F;margin:0 0 18px}}
.r{{display:flex;gap:44px}} figure{{margin:0}} img{{width:402px;border-radius:44px;box-shadow:0 12px 40px rgba(43,38,34,.18);display:block}}
figcaption{{text-align:center;margin-top:14px;font-size:20px;color:#2B2622;font-weight:600}}
.sw{{display:flex;gap:14px;align-items:center;margin-top:8px}} .sw b{{width:44px;height:44px;border-radius:12px;display:block;box-shadow:inset 0 0 0 1px rgba(0,0,0,.08)}} .sw span{{color:#6B625A;font-size:16px;margin-right:18px}}
</style></head><body>
<h1>Quiet Canvas</h1><p class="lead">Paint by number for calm minds · Direction A: Paper &amp; Terracotta · New York + SF Pro · SF Symbols</p>
<div class="sw"><b style="background:#FAF6F0"></b><span>Paper</span><b style="background:#fff"></b><span>Surface</span><b style="background:#2B2622"></b><span>Ink</span><b style="background:#6B625A"></b><span>Ink 2</span><b style="background:#B4532F"></b><span>Terracotta</span><b style="background:#4E8B5F"></b><span>Success</span><b style="background:#E07B39"></b><span>Flame</span><b style="background:#E8E1D7"></b><span>Line</span></div>
{rows}</body></html>"""
open(f"{OUT}/board.html", "w").write(board)
subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                "--window-size=1434,4300", "--virtual-time-budget=4000", f"--screenshot={OUT}/board.png", f"file://{OUT}/board.html"],
               stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
print("ok", sorted(os.listdir(OUT)))

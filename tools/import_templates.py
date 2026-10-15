#!/usr/bin/env python3
"""Import paint-by-number templates from the generator output into the app bundle.

Usage:
    python3 tools/import_templates.py [OUTPUT_DIR]

OUTPUT_DIR defaults to ~/Documents/Mine/ColorNumber-GenerateImage-Tool/output and holds one folder per
theme (`01_greenhouse_sanctuary/`), each with `{id}.json` + `{id}.png` per picture.

For every picture this writes into Coloring-PaintTheNumber/Templates:
  - {id}.json  minified template (regions, palette)
  - {id}.jpg   600px thumbnail
  - {id}_art.jpg  1024px artwork shown when the picture is finished
and merges it into catalog.json. Existing catalog fields (title, free, added) are kept, so edit
titles by hand in catalog.json and re-run safely. New themes get a title from their slug.
"""
import datetime, json, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEST = os.path.join(ROOT, "Coloring-PaintTheNumber", "Templates")
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Documents/Mine/ColorNumber-GenerateImage-Tool/output")
CHALLENGE_SRC = os.path.join(os.path.dirname(SRC), "output_hard", "masterpiece_worlds")
PIPELINE_DATA = os.path.join(os.path.dirname(SRC), "configs", "pipeline_data.json")
NAME = re.compile(r"^(\d+)_(easy|normal|hard)_(.+)\.json$")


def title_case(slug):
    return " ".join(w.capitalize() for w in slug.split("_"))


def challenge_titles():
    if not os.path.exists(PIPELINE_DATA):
        return {}
    data = json.load(open(PIPELINE_DATA))
    theme = next((t for t in data.get("themes", []) if t.get("slug") == "masterpiece_worlds"), {})
    out = {}
    for p in theme.get("prompts", []):
        m = re.search(r"\(([^)]+)\)", p.get("subtheme", ""))
        if m:
            out[p["id"]] = m.group(1).strip()
    return out


def import_folder(path, theme_id, old_entries, today, problems, titles=None):
    files = sorted((f for f in os.listdir(path) if NAME.match(f)), key=lambda f: int(NAME.match(f).group(1)))
    entries = []
    for f in files:
        seq, difficulty, _ = NAME.match(f).groups()
        num = int(seq[2:]) if len(seq) == 4 and theme_id != "masterpiece_worlds" else int(seq)
        pid = f[:-5]
        data = json.load(open(os.path.join(path, f)))
        regions, palette = data["regions"], data["palette"]
        if not regions or any("label" not in r or "bbox" not in r for r in regions):
            problems.append(f"{pid}: missing regions/labels/bbox")
            continue
        json.dump({k: data[k] for k in ("width", "height", "palette", "regions")},
                  open(os.path.join(DEST, pid + ".json"), "w"), separators=(",", ":"))
        png = os.path.join(path, pid + ".png")
        # 600px thumbnail for lists, 1024px artwork revealed when a picture is finished
        for suffix, side, quality in ((".jpg", "600", "72"), ("_art.jpg", "1024", "80")):
            jpg = os.path.join(DEST, pid + suffix)
            if os.path.exists(png) and (not os.path.exists(jpg) or os.path.getmtime(png) > os.path.getmtime(jpg)):
                subprocess.run(["sips", "-Z", side, "-s", "format", "jpeg", "-s", "formatOptions", quality, png, "--out", jpg],
                               check=True, stdout=subprocess.DEVNULL)
        prev = old_entries.get(pid, {})
        default_title = (titles or {}).get(num, f"{title_case(theme_id)} {num}")
        entries.append({
            "id": pid,
            "title": prev.get("title", default_title),
            "theme": theme_id,
            "difficulty": difficulty,
            "free": prev.get("free"),
            "regions": len(regions),
            "colors": len(palette),
            "added": prev.get("added", today),
            "thumb": pid + ".jpg",
        })
    return entries


def main():
    catalog_path = os.path.join(DEST, "catalog.json")
    old = json.load(open(catalog_path)) if os.path.exists(catalog_path) else {"themes": [], "templates": [], "challenges": []}
    old_themes = {t["id"]: t for t in old["themes"]}
    old_entries = {e["id"]: e for e in old["templates"] + old.get("challenges", [])}
    today = datetime.date.today().isoformat()
    themes, entries, problems = [], [], []

    for folder in sorted(os.listdir(SRC)):
        path = os.path.join(SRC, folder)
        if not os.path.isdir(path):
            continue
        theme_id = re.sub(r"^\d+_", "", folder)
        theme_entries = import_folder(path, theme_id, old_entries, today, problems)
        if not theme_entries:
            continue
        # default: first easy and first normal picture of each theme are free
        if all(e["free"] is None for e in theme_entries):
            for level in ("easy", "normal"):
                first = next((e for e in theme_entries if e["difficulty"] == level), None)
                if first:
                    first["free"] = True
        for e in theme_entries:
            e["free"] = bool(e["free"])
        prev_theme = old_themes.get(theme_id, {})
        cover = next((e["id"] for e in theme_entries if e["difficulty"] == "easy"), theme_entries[0]["id"])
        themes.append({"id": theme_id, "title": prev_theme.get("title", title_case(theme_id)),
                       "cover": prev_theme.get("cover", cover)})
        entries += theme_entries

    challenges = []
    if os.path.isdir(CHALLENGE_SRC):
        challenges = import_folder(CHALLENGE_SRC, "masterpiece_worlds", old_entries, today, problems, challenge_titles())
        for e in challenges:
            e["free"] = bool(e["free"])

    json.dump({"version": 1, "themes": themes, "templates": entries, "challenges": challenges},
              open(catalog_path, "w"), indent=1, ensure_ascii=False)
    size = sum(os.path.getsize(os.path.join(DEST, f)) for f in os.listdir(DEST))
    print(f"{len(themes)} themes, {len(entries)} templates, {len(challenges)} challenges, Templates/ = {size / 1e6:.1f} MB")
    for p in problems:
        print("SKIPPED", p)


if __name__ == "__main__":
    main()


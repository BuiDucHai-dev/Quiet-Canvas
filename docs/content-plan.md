# Content plan (Phase C)

Goal: ~96 production-ready templates across 8 themes before any more app work.
Status: draft. Numbers marked (calibrate) must be checked against the first pilot batch.

## 1. Targets

| Item | Target |
|---|---|
| Themes | 8 |
| Templates per theme | 12 |
| Total | 96 |
| Difficulty mix | easy 30% / normal 50% / hard 20% |
| Free per theme | 2 (1 easy, 1 normal) = 16 free |

Reference sample (`001_normal_ocean_friends_1`): 1024x1024, 19 colors, 127 regions = "normal".
Proposed bands (calibrate): easy <= 80 regions / <= 14 colors; normal 80-250 / 14-24; hard 250-600 / 20-32.

## 2. Themes and briefs

Audience for all: adults 35-65 who color to relax. Style: calm, balanced composition, soft but distinguishable palette, clear subject.

| # | Theme | Subjects (examples) | Watch out |
|---|---|---|---|
| 1 | Faith | Noah's ark, creation, good shepherd, nativity, dove, lamb, rainbow, church in landscape, psalm pastures, loaves and fishes | Respectful, non-denominational. Avoid close-up faces of Jesus (use distance or back view). Verse text only from public-domain translations (KJV). Human review of every image |
| 2 | Cats and Dogs | breeds, cat on windowsill, puppy in garden, sleeping pets, pet with flowers | Anatomy errors (paws, eyes). No branded characters |
| 3 | Flowers | bouquets, vases, wildflower fields, roses, sunflowers, lavender | Many similar greens/pinks: palette distinctness check matters most here |
| 4 | Mandala | floral, geometric, animal, seasonal mandalas | Symmetry must hold after region merge. Hard regions risk tiny cells |
| 5 | Cozy Home | reading nook, cabin in snow, tea table, bakery, rainy window | Avoid clutter; one focal point |
| 6 | Ocean | friends, coral reef, lighthouse, sea turtle, sailboat | Existing sample lives here |
| 7 | Nature and Landscapes | mountains, forest, lake sunrise, countryside, autumn path | Gradients (sky) produce many near-identical regions: cap color count |
| 8 | Holidays | Christmas first (winter cabin, tree, wreath, snowman), later Easter, autumn harvest | Time-bound: see section 6 |

Prompt rules for the generator: no living-artist styles, no trademarked characters or logos, no text inside the image, no photorealism (flat/illustrated), white or simple background, subject fills 70-85% of the canvas.

## 3. File naming

Keep the existing pattern: `{seq:03}_{difficulty}_{subject}_{n}` (e.g. `014_easy_sleeping_cat_1`).
Theme lives in the catalog, not the filename, so a template can change theme without renaming.

## 4. Catalog schema (pipeline output, consumed by the app)

`catalog.json`:

```json
{
  "version": 1,
  "templates": [
    {
      "id": "001_normal_ocean_friends_1",
      "title": "Ocean Friends",
      "theme": "ocean",
      "difficulty": "normal",
      "free": true,
      "regions": 127,
      "colors": 19,
      "added": "2026-10-06",
      "thumb": "001_normal_ocean_friends_1.webp"
    }
  ]
}
```

Per template files: `{id}.json` (minified) and `{id}.webp` thumbnail (256px, ~30KB). No full-size PNG in the app bundle.
Budget: JSON <= 200KB raw each; whole catalog <= 10MB uncompressed.

## 5. Quality gates (automatic, per template)

Reject or regenerate if any fails:

1. Colors within the band for its difficulty; palette colors pairwise distinguishable (perceptual distance above a threshold, calibrate).
2. No region below the minimum readable area (label font size >= ~5px at fit-to-screen, matching the app's draw cutoff).
3. Regions cover the canvas with no gaps or overlaps (render all regions filled; compare to source image; similarity above threshold).
4. No two adjacent regions share a color unless intentionally merged.
5. Every region has a label position inside its own path.
6. File size within budget; JSON decodes with the app's `Template` struct.

Manual gate (about 30-60 seconds each): look at the thumbnail and the filled render. Reject anatomy errors, odd faces, off-theme content, offensive or unclear subjects. Faith theme: 100% manual review, no exceptions.

## 6. Order of work

1. Pilot: one theme (Cats and Dogs or Flowers), 12 templates. Record: generation pass rate, rejection reasons, time and cost per accepted template, difficulty accuracy vs the bands above. Fix prompts and gates.
2. Scale to remaining themes in parallel batches of 12, applying lessons from the pilot.
3. Holidays/Christmas first if a release before December is wanted: App Review takes up to about a week, so the build with Christmas content should be submitted by mid-November.
4. Export `catalog.json` and thumbnails, run the size budget check.
5. Freeze the 96 as launch content. New content after launch is tracked per theme with the metrics from the roadmap.

## 7. Open items

- Where the pipeline lives (not in this repo) and its current output fields vs the catalog schema above.
- Cost and time per template at the current pipeline settings.
- Legal check on AI-generated art: copyright protection for purely AI-generated images is weak in some jurisdictions, and App Store listings may need disclosure. Verify before launch.

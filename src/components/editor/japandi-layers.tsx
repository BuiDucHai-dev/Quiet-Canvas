"use client";
import * as React from "react";
import type { Slide } from "@/lib/types";

const JAPANDI_SLIDE_META = [
  { jp: "余白", gloss: "yohaku · quiet space", seal: "静", subhead: "Every picture, waiting for a calm hour." },
  { jp: "一筆", gloss: "hitofude · one stroke", seal: "彩", subhead: "Tap a number and watch the pigment settle." },
  { jp: "四季", gloss: "shiki · the seasons", seal: "花", subhead: "Eight curated collections, drawn for slow evenings." },
  { jp: "夜", gloss: "yoru · evening", seal: "静", subhead: "Soft paper tones that never tire your eyes." },
  { jp: "暦", gloss: "koyomi · daily rhythm", seal: "日", subhead: "One gentle picture a day, with a rest day built in." },
  { jp: "手元", gloss: "temoto · at hand", seal: "画", subhead: "" },
];

const CLOSER_ROWS: { key: string; value: string }[] = [
  { key: "COLLECTION", value: "Ninety-six illustrations across eight themes." },
  { key: "GUIDANCE", value: "Soft stripe hints and smart edge-tap fill." },
  { key: "RHYTHM", value: "Daily challenges with one weekly rest day." },
  { key: "COMFORT", value: "Warm washi paper palette, zero harsh glare." },
  { key: "PRIVACY", value: "Offline-ready. No ads, no noisy timers." },
];

function mulberry32(a: number) {
  return function () {
    let t = (a += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const SPECKS = (() => {
  const rnd = mulberry32(42);
  const iron: { cx: number; cy: number; r: number; o: number }[] = [];
  const pale: { cx: number; cy: number; r: number; o: number }[] = [];
  for (let i = 0; i < 95; i++) {
    iron.push({
      cx: 68 + rnd() * 284,
      cy: 64 + rnd() * 255,
      r: 0.8 + rnd() * 1.8,
      o: 0.25 + rnd() * 0.35,
    });
  }
  for (let i = 0; i < 45; i++) {
    pale.push({
      cx: 72 + rnd() * 276,
      cy: 68 + rnd() * 245,
      r: 0.7 + rnd() * 1.4,
      o: 0.25 + rnd() * 0.25,
    });
  }
  return { iron, pale };
})();

export function JapandiYunomi({
  width,
  style,
  uid = "y",
}: {
  width: number;
  style?: React.CSSProperties;
  uid?: string;
}) {
  const height = width * (380 / 420);
  const cId = `clip-${uid}`;
  const b3 = `b3-${uid}`;
  const b6 = `b6-${uid}`;
  const b12 = `b12-${uid}`;
  const glaze = `glaze-${uid}`;
  const ame = `ame-${uid}`;
  const clay = `clay-${uid}`;
  const coffee = `coffee-${uid}`;
  const ao = `ao-${uid}`;

  return (
    <svg
      viewBox="0 0 420 380"
      width={width}
      height={height}
      style={{ overflow: "visible", pointerEvents: "none", ...style }}
      aria-hidden
    >
      <defs>
        <clipPath id={cId}>
          <path d="M60,52 C57,118 64,222 82,296 C88,322 124,336 210,337 C296,336 332,322 338,296 C356,222 363,118 360,52 A150,30 0 0 1 60,52 Z" />
        </clipPath>
        <filter id={b3} x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur stdDeviation="3" />
        </filter>
        <filter id={b6} x="-20%" y="-20%" width="140%" height="140%">
          <feGaussianBlur stdDeviation="6" />
        </filter>
        <filter id={b12} x="-30%" y="-30%" width="160%" height="160%">
          <feGaussianBlur stdDeviation="13" />
        </filter>
        <linearGradient id={glaze} x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#6E675E" />
          <stop offset="13%" stopColor="#A09888" />
          <stop offset="30%" stopColor="#BDB5A6" />
          <stop offset="55%" stopColor="#A69E8F" />
          <stop offset="82%" stopColor="#80796D" />
          <stop offset="100%" stopColor="#5C564D" />
        </linearGradient>
        <linearGradient id={ame} x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#6B4A2E" />
          <stop offset="30%" stopColor="#A8804F" />
          <stop offset="60%" stopColor="#8E6A42" />
          <stop offset="100%" stopColor="#553A24" />
        </linearGradient>
        <linearGradient id={clay} x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#8A6446" />
          <stop offset="30%" stopColor="#C39A72" />
          <stop offset="60%" stopColor="#AE8560" />
          <stop offset="100%" stopColor="#6E4E36" />
        </linearGradient>
        <radialGradient id={coffee} cx="46%" cy="44%" r="55%">
          <stop offset="0%" stopColor="#4E3423" />
          <stop offset="62%" stopColor="#2C1D13" />
          <stop offset="100%" stopColor="#1C130D" />
        </radialGradient>
        <linearGradient id={ao} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#FFFFFF" stopOpacity="0.10" />
          <stop offset="55%" stopColor="#FFFFFF" stopOpacity="0" />
          <stop offset="100%" stopColor="#2A1E14" stopOpacity="0.28" />
        </linearGradient>
      </defs>

      {/* Long cast shadow + tight contact shadow */}
      <ellipse cx="262" cy="344" rx="178" ry="20" fill="#5A4632" opacity="0.22" filter={`url(#${b12})`} />
      <ellipse cx="214" cy="342" rx="118" ry="9" fill="#3B2C1E" opacity="0.44" filter={`url(#${b3})`} />

      {/* Unglazed clay foot */}
      <path
        d="M122,322 C124,334 126,343 132,346 L290,346 C296,343 298,334 300,322 Z"
        fill={`url(#${clay})`}
      />

      {/* Main cylindrical ash-glaze body */}
      <path
        d="M60,52 C57,118 64,222 82,296 C88,322 124,336 210,337 C296,336 332,322 338,296 C356,222 363,118 360,52 A150,30 0 0 1 60,52 Z"
        fill={`url(#${glaze})`}
      />

      <g clipPath={`url(#${cId})`}>
        {/* Lower unglazed clay skirt + wavy glaze roll */}
        <path
          d="M55,286 Q115,274 172,288 T285,282 T368,290 L370,350 L55,350 Z"
          fill={`url(#${clay})`}
        />
        <path
          d="M55,286 Q115,274 172,288 T285,282 T368,290"
          fill="none"
          stroke="#4E3B29"
          strokeWidth="7"
          opacity="0.38"
          filter={`url(#${b3})`}
        />

        {/* Amber ame glaze rim band with 5 organic drips */}
        <path
          d="M54,48 L366,48 L366,94 C346,96 336,124 326,124 C316,124 310,95 286,95 C268,95 262,152 248,152 C234,152 228,96 202,96 C184,96 178,134 166,134 C154,134 148,94 126,94 C112,94 106,118 95,118 C84,118 78,92 54,92 Z"
          fill={`url(#${ame})`}
          opacity="0.92"
        />
        <path
          d="M54,92 C78,92 84,118 95,118 C106,118 112,94 126,94 C148,94 154,134 166,134 C178,134 184,96 202,96 C228,96 234,152 248,152 C262,152 268,95 286,95 C310,95 316,124 326,124 C336,124 346,96 366,94"
          fill="none"
          stroke="#4A321F"
          strokeWidth="4"
          opacity="0.52"
          filter={`url(#${b3})`}
        />

        {/* Throwing rings */}
        <path d="M62,168 Q210,184 358,168" fill="none" stroke="#3E3730" strokeWidth="3.5" opacity="0.12" />
        <path d="M62,172 Q210,188 358,172" fill="none" stroke="#FFFFFF" strokeWidth="2" opacity="0.09" />
        <path d="M68,224 Q210,240 352,224" fill="none" stroke="#3E3730" strokeWidth="3.5" opacity="0.12" />
        <path d="M68,228 Q210,244 352,228" fill="none" stroke="#FFFFFF" strokeWidth="2" opacity="0.09" />

        {/* Iron & pale mineral specks */}
        {SPECKS.iron.map((s, i) => (
          <circle key={`i-${i}`} cx={s.cx} cy={s.cy} r={s.r} fill="#4A3526" opacity={s.o} />
        ))}
        {SPECKS.pale.map((s, i) => (
          <circle key={`p-${i}`} cx={s.cx} cy={s.cy} r={s.r} fill="#FFF8EC" opacity={s.o} />
        ))}

        {/* Vertical ambient occlusion */}
        <rect x="50" y="45" width="320" height="300" fill={`url(#${ao})`} />

        {/* Specular highlight streak on lit left side */}
        <path
          d="M108,66 C103,135 108,218 118,282"
          fill="none"
          stroke="#FFFBF2"
          strokeWidth="16"
          strokeLinecap="round"
          opacity="0.42"
          filter={`url(#${b6})`}
        />
        <path
          d="M110,72 C106,135 110,212 119,274"
          fill="none"
          stroke="#FFFFFF"
          strokeWidth="4"
          strokeLinecap="round"
          opacity="0.55"
        />
      </g>

      {/* Rim ellipses & dark roasted tea/coffee liquid */}
      <ellipse cx="210" cy="52" rx="150" ry="30" fill="#8E6A42" />
      <ellipse cx="210" cy="51" rx="146" ry="27.5" fill="#C9AB82" />
      <ellipse cx="210" cy="53" rx="139" ry="25" fill="#5E4230" />
      <ellipse cx="210" cy="58" rx="136" ry="22" fill={`url(#${coffee})`} />
      <ellipse cx="170" cy="54" rx="52" ry="7" fill="#F4E6D0" opacity="0.24" filter={`url(#${b3})`} />
    </svg>
  );
}

export function JapandiHanko({
  glyph,
  size,
  inverted,
  uid = "h",
}: {
  glyph: string;
  size: number;
  inverted?: boolean;
  uid?: string;
}) {
  const fId = `seal-rough-${uid}`;
  return (
    <svg
      viewBox="0 0 120 120"
      width={size}
      height={size}
      style={{ display: "block", pointerEvents: "none" }}
      aria-hidden
    >
      <defs>
        <filter id={fId} x="-10%" y="-10%" width="120%" height="120%">
          <feTurbulence type="fractalNoise" baseFrequency="0.055" numOctaves="2" seed="5" result="t" />
          <feDisplacementMap in="SourceGraphic" in2="t" scale="2.8" xChannelSelector="R" yChannelSelector="G" />
        </filter>
      </defs>
      <g filter={`url(#${fId})`}>
        <rect x="4" y="4" width="112" height="112" rx="8" fill="#C8321E" />
        {inverted && (
          <rect
            x="10"
            y="10"
            width="100"
            height="100"
            rx="5"
            fill="none"
            stroke="#F3F0EA"
            strokeWidth="3"
            opacity="0.88"
          />
        )}
        <text
          x="60"
          y="88"
          textAnchor="middle"
          fontFamily="var(--font-seal), var(--font-mincho), serif"
          fontSize="78"
          fill="#F3F0EA"
        >
          {glyph}
        </text>
      </g>
    </svg>
  );
}

export function JapandiBackdrop({
  slide,
  cW,
  cH,
  index,
}: {
  slide: Slide;
  cW: number;
  cH: number;
  index: number;
}) {
  const inverted = !!slide.inverted;
  const s = cW / 1320;
  const meta = JAPANDI_SLIDE_META[index % JAPANDI_SLIDE_META.length];
  const isPlinth = slide.layout === "device-top";
  const isCloser = slide.layout === "no-device";
  const shelfTop = isCloser ? Math.round(2560 * (cH / 2868)) : Math.round(2727 * (cH / 2868));
  const plinthTop = Math.round(2155 * (cH / 2868));

  return (
    <div
      aria-hidden
      style={{
        position: "absolute",
        inset: 0,
        overflow: "hidden",
        background: slide.backgroundColor || (inverted ? "#1E1D1B" : "#F3F0EA"),
        pointerEvents: "none",
      }}
    >
      {/* Window-light 3-stop wash */}
      <div className={inverted ? "japandi-wash-dark" : "japandi-wash"} />

      {/* Washi kozo fibres */}
      <div
        className="japandi-fibre"
        style={{
          opacity: inverted ? 0.09 : 1,
          filter: inverted ? "invert(1)" : undefined,
        }}
      />

      {/* Subtle tactile paper grain */}
      <svg
        width={cW}
        height={cH}
        style={{
          position: "absolute",
          inset: 0,
          mixBlendMode: "overlay",
          opacity: inverted ? 0.22 : 0.16,
          pointerEvents: "none",
        }}
      >
        <filter id={`jp-grain-${index}`}>
          <feTurbulence type="fractalNoise" baseFrequency="0.65" numOctaves="3" stitchTiles="stitch" />
        </filter>
        <rect width="100%" height="100%" filter={`url(#jp-grain-${index})`} />
      </svg>

      {/* Structure: Stone plinth on device-top, Oak shelf on all other slides */}
      {isPlinth ? (
        <div
          style={{
            position: "absolute",
            left: Math.round(170 * s),
            top: plinthTop,
            width: Math.round(1220 * s),
            height: Math.round(132 * s),
            boxShadow:
              "0 26px 40px -10px rgba(84, 64, 40, 0.22), 0 70px 110px -30px rgba(84, 64, 40, 0.16)",
          }}
        >
          <div
            style={{
              height: Math.round(30 * s),
              background: "linear-gradient(90deg, #F6F3EE, #EFEBE4 55%, #E9E4DB)",
              boxShadow: "inset 0 1px 0 rgba(255, 255, 255, 0.9)",
            }}
          />
          <div
            style={{
              height: Math.round(102 * s),
              background: "linear-gradient(180deg, #E2DCD1, #DAD3C6 60%, #D2CABC)",
            }}
          />
        </div>
      ) : (
        <div
          className={inverted ? "japandi-shelf japandi-shelf-dark" : "japandi-shelf"}
          style={{
            top: shelfTop,
            height: Math.max(24, Math.round(32 * s)),
          }}
        />
      )}

      {/* Vertical Japanese word + gloss + one vermilion Hanko seal */}
      <div
        style={{
          position: "absolute",
          right: Math.round(88 * s),
          top: isPlinth ? Math.round(2296 * (cH / 2868)) : Math.round(150 * (cH / 2868)),
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: Math.round(38 * s),
        }}
      >
        <div
          style={{
            display: "flex",
            flexDirection: "row-reverse",
            gap: Math.round(22 * s),
            alignItems: "flex-start",
          }}
        >
          <div
            lang="ja"
            style={{
              writingMode: "vertical-rl",
              fontFamily: "var(--font-mincho), Georgia, serif",
              fontWeight: 500,
              fontSize: Math.round((isPlinth ? 102 : 116) * s),
              lineHeight: 1,
              letterSpacing: "0.12em",
              color: inverted ? "#F3F0EA" : "#1E1D1B",
            }}
          >
            {meta.jp}
          </div>
          <div
            style={{
              width: Math.max(1.5, 1.5 * s),
              height: Math.round(196 * s),
              background: "#8C8A85",
              opacity: 0.6,
              marginTop: Math.round(12 * s),
            }}
          />
          <div
            style={{
              writingMode: "vertical-rl",
              fontFamily: "var(--font-kaku), sans-serif",
              fontWeight: 500,
              fontSize: Math.round(29 * s),
              lineHeight: 1,
              letterSpacing: "0.28em",
              color: inverted ? "#B8B4AC" : "#4E4B46",
              marginTop: Math.round(10 * s),
              textTransform: "lowercase",
            }}
          >
            {meta.gloss}
          </div>
        </div>
        <JapandiHanko
          glyph={meta.seal}
          size={Math.round((isPlinth ? 98 : 108) * s)}
          inverted={inverted}
          uid={`seal-${index}`}
        />
      </div>

      {/* Closer slide (no-device): 5-row specification table + wordmark + large Yunomi */}
      {isCloser && (
        <>
          <div
            style={{
              position: "absolute",
              left: Math.round(108 * s),
              top: Math.round(740 * (cH / 2868)),
              width: Math.round(1040 * s),
              borderBottom: `${Math.max(1.5, 1.5 * s)}px solid rgba(140, 138, 133, 0.55)`,
            }}
          >
            {CLOSER_ROWS.map((row) => (
              <div
                key={row.key}
                style={{
                  display: "flex",
                  alignItems: "baseline",
                  height: Math.round(146 * (cH / 2868)),
                  borderTop: `${Math.max(1.5, 1.5 * s)}px solid rgba(140, 138, 133, 0.55)`,
                }}
              >
                <div
                  style={{
                    width: Math.round(256 * s),
                    flexShrink: 0,
                    fontFamily: "var(--font-kaku), sans-serif",
                    fontWeight: 500,
                    fontSize: Math.round(29 * s),
                    letterSpacing: "0.30em",
                    color: inverted ? "#B8B4AC" : "#4E4B46",
                  }}
                >
                  {row.key}
                </div>
                <div
                  style={{
                    fontFamily: "var(--font-mincho), Georgia, serif",
                    fontWeight: 500,
                    fontSize: Math.round(50 * s),
                    letterSpacing: "-0.005em",
                    color: inverted ? "#F3F0EA" : "#1E1D1B",
                    lineHeight: 1.1,
                  }}
                >
                  {row.value}
                </div>
              </div>
            ))}
          </div>

          <div
            style={{
              position: "absolute",
              left: Math.round(108 * s),
              top: Math.round(2310 * (cH / 2868)),
            }}
          >
            <div
              style={{
                fontFamily: "var(--font-mincho), Georgia, serif",
                fontWeight: 500,
                fontSize: Math.round(82 * s),
                lineHeight: 1,
                color: inverted ? "#F3F0EA" : "#1E1D1B",
              }}
            >
              Quiet Canvas
            </div>
            <div
              style={{
                marginTop: Math.round(18 * s),
                fontFamily: "var(--font-kaku), sans-serif",
                fontWeight: 500,
                fontSize: Math.round(30 * s),
                letterSpacing: "0.32em",
                color: inverted ? "#B8B4AC" : "#4E4B46",
              }}
            >
              FOR IPHONE &amp; IPAD
            </div>
          </div>

          <JapandiYunomi
            width={Math.round(740 * s)}
            uid={`closer-cup-${index}`}
            style={{
              position: "absolute",
              left: Math.round(530 * s),
              top: shelfTop - Math.round(740 * s * (344 / 420)),
            }}
          />
        </>
      )}
    </div>
  );
}

export function JapandiForegroundObject({
  slide,
  cW,
  cH,
  index,
  deviceX,
}: {
  slide: Slide;
  cW: number;
  cH: number;
  index: number;
  deviceX?: number;
}) {
  // Per 17-quiet-japandi.md:
  // - Slide 3 (device-top / plinth) and Slide 4 (inverted sumi) have NO foreground object.
  // - Slide 6 (no-device) renders its large cup in JapandiBackdrop.
  if (slide.inverted || slide.layout === "device-top" || slide.layout === "no-device" || slide.layout === "feature-graphic") {
    return null;
  }
  const s = cW / 1320;
  const shelfTop = Math.round(2727 * (cH / 2868));
  const cupW = Math.round(404 * s);
  const cupFootY = Math.round(cupW * (344 / 420));
  const phoneOnRight = (deviceX ?? 0) > cW * 0.14;
  const left = phoneOnRight ? Math.round(18 * s) : Math.round(902 * s);

  return (
    <div
      aria-hidden
      style={{
        position: "absolute",
        left,
        top: shelfTop - cupFootY,
        zIndex: 6,
        pointerEvents: "none",
      }}
    >
      <JapandiYunomi width={cupW} uid={`fg-cup-${index}`} />
    </div>
  );
}

export function getJapandiSubhead(index: number): string {
  return JAPANDI_SLIDE_META[index % JAPANDI_SLIDE_META.length]?.subhead || "";
}

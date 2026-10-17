import { DEFAULT_LOCALE } from "./locale";
import { PLATFORM_DEVICES, PROJECT_SCHEMA_VERSION } from "./constants";
import type { Device, Platform, ProjectState, Slide } from "./types";

let _id = 0;
export const nid = () => `s_${Date.now().toString(36)}_${(_id++).toString(36)}`;

const en = (s: string) => ({ [DEFAULT_LOCALE]: s });

function iphoneQuietCanvas(): Slide[] {
  return [
    {
      id: "qc_iphone_1",
      layout: "hero",
      label: en("QUIET CANVAS · SANCTUARY"),
      headline: en("Color at your\nown pace."),
      screenshot: "/screenshots/apple/iphone/en/01.png",
      transforms: {
        caption: { x: 100, y: 157, width: 912, height: 513, rotation: 0, zIndex: 4 },
        device: { x: 64, y: 716, width: 990, height: 2017, rotation: 0, zIndex: 3 },
      },
      typography: { headlineScale: 0.95 },
    },
    {
      id: "qc_iphone_2",
      layout: "device-bottom",
      label: en("PAINT BY NUMBER · GUIDED"),
      headline: en("One gentle stroke\nat a time."),
      screenshot: "/screenshots/apple/iphone/en/02.png",
      transforms: {
        caption: { x: 100, y: 147, width: 928, height: 533, rotation: 0, zIndex: 4 },
        device: { x: 266, y: 716, width: 990, height: 2017, rotation: 0, zIndex: 3 },
      },
      typography: { headlineScale: 0.95 },
    },
    {
      id: "qc_iphone_3",
      layout: "device-top",
      label: en("CURATED LIBRARY · 8 THEMES"),
      headline: en("Ninety-six worlds,\ndrawn with care."),
      screenshot: "/screenshots/apple/iphone/en/03.png",
      transforms: {
        device: { x: 230, y: 150, width: 990, height: 2017, rotation: 0, zIndex: 3 },
        caption: { x: 100, y: 2213, width: 948, height: 567, rotation: 0, zIndex: 4 },
      },
      typography: { headlineScale: 0.75 },
    },
    {
      id: "qc_iphone_4",
      layout: "device-bottom",
      label: en("DAILY RHYTHM · STREAKS"),
      headline: en("A calm habit,\nkept daily."),
      screenshot: "/screenshots/apple/iphone/en/04.png",
      inverted: true,
      transforms: {
        caption: { x: 100, y: 160, width: 880, height: 413, rotation: 0, zIndex: 4 },
        device: { x: 64, y: 716, width: 990, height: 2017, rotation: 0, zIndex: 3 },
      },
      typography: { headlineScale: 0.9 },
    },
    {
      id: "qc_iphone_5",
      layout: "device-bottom",
      label: en("YOUR GALLERY · MY WORKS"),
      headline: en("Every piece,\nkept close."),
      screenshot: "/screenshots/apple/iphone/en/05.png",
      transforms: {
        caption: { x: 100, y: 210, width: 894, height: 460, rotation: 0, zIndex: 4 },
        device: { x: 266, y: 716, width: 990, height: 2017, rotation: 0, zIndex: 3 },
      },
      typography: { headlineScale: 0.9 },
    },
    {
      id: "qc_iphone_6",
      layout: "no-device",
      label: en("QUIET CANVAS · FOR IPHONE & IPAD"),
      headline: en("Only what you\nneed."),
      screenshot: "/screenshots/apple/iphone/en/06.png",
      transforms: {
        caption: { x: 100, y: 210, width: 1080, height: 480, rotation: 0, zIndex: 4 },
      },
    },
  ];
}

function ipadQuietCanvas(): Slide[] {
  return [
    {
      id: "qc_ipad_1",
      layout: "hero",
      label: en("QUIET CANVAS · SANCTUARY"),
      headline: en("Color at your\nown pace."),
      screenshot: "/screenshots/apple/ipad/en/01.png",
      transforms: {
        caption: { x: 156, y: 145, width: 1360, height: 460, rotation: 0, zIndex: 4 },
        device: { x: 140, y: 771, width: 1420, height: 1846, rotation: 0, zIndex: 3 },
      },
    },
    {
      id: "qc_ipad_2",
      layout: "device-bottom",
      label: en("PAINT BY NUMBER · GUIDED"),
      headline: en("One gentle stroke\nat a time."),
      screenshot: "/screenshots/apple/ipad/en/02.png",
      transforms: {
        caption: { x: 156, y: 145, width: 1360, height: 450, rotation: 0, zIndex: 4 },
        device: { x: 504, y: 771, width: 1420, height: 1846, rotation: 0, zIndex: 3 },
      },
    },
    {
      id: "qc_ipad_3",
      layout: "device-top",
      label: en("CURATED LIBRARY · 8 THEMES"),
      headline: en("Ninety-six worlds,\ndrawn with care."),
      screenshot: "/screenshots/apple/ipad/en/03.png",
      transforms: {
        device: { x: 380, y: 140, width: 1420, height: 1846, rotation: 0, zIndex: 3 },
        caption: { x: 156, y: 2226, width: 1360, height: 440, rotation: 0, zIndex: 4 },
      },
    },
    {
      id: "qc_ipad_4",
      layout: "device-bottom",
      label: en("DAILY RHYTHM · STREAKS"),
      headline: en("A calm habit,\nkept daily."),
      screenshot: "/screenshots/apple/ipad/en/04.png",
      inverted: true,
      transforms: {
        caption: { x: 156, y: 145, width: 1360, height: 450, rotation: 0, zIndex: 4 },
        device: { x: 140, y: 771, width: 1420, height: 1846, rotation: 0, zIndex: 3 },
      },
    },
    {
      id: "qc_ipad_5",
      layout: "device-bottom",
      label: en("YOUR GALLERY · MY WORKS"),
      headline: en("Every piece,\nkept close."),
      screenshot: "/screenshots/apple/ipad/en/05.png",
      transforms: {
        caption: { x: 156, y: 145, width: 1360, height: 450, rotation: 0, zIndex: 4 },
        device: { x: 504, y: 771, width: 1420, height: 1846, rotation: 0, zIndex: 3 },
      },
    },
    {
      id: "qc_ipad_6",
      layout: "no-device",
      label: en("QUIET CANVAS · FOR IPHONE & IPAD"),
      headline: en("Only what you\nneed."),
      screenshot: "/screenshots/apple/ipad/en/06.png",
      transforms: {
        caption: { x: 156, y: 160, width: 1600, height: 480, rotation: 0, zIndex: 4 },
      },
    },
  ];
}

function creativeUniversalQuietCanvas(): Slide[] {
  return [
    {
      id: "qc_creative_universal_1",
      layout: "split-landscape",
      label: en("QUIET CANVAS · SANCTUARY"),
      headline: en("Color at your\nown pace."),
      screenshot: "/screenshots/apple/iphone/en/02.png",
      transforms: {
        caption: { x: 1940, y: 740, width: 760, height: 620, rotation: 0, zIndex: 4 },
        device: { x: 2740, y: 680, width: 462, height: 941, rotation: 0, zIndex: 3 },
      },
    },
  ];
}

function creativeHeaderQuietCanvas(): Slide[] {
  return [
    {
      id: "qc_creative_header_1",
      layout: "split-landscape",
      label: en("QUIET CANVAS · SANCTUARY"),
      headline: en("Color at your\nown pace."),
      screenshot: "/screenshots/apple/iphone/en/02.png",
      transforms: {
        caption: { x: 1120, y: 540, width: 900, height: 500, rotation: 0, zIndex: 4 },
        device: { x: 2150, y: 496, width: 325, height: 662, rotation: 0, zIndex: 3 },
      },
    },
  ];
}

function creativeSearchQuietCanvas(): Slide[] {
  return [
    {
      id: "qc_creative_search_1",
      layout: "split-landscape",
      label: en("QUIET CANVAS · SANCTUARY"),
      headline: en("Color at your\nown pace."),
      screenshot: "/screenshots/apple/iphone/en/02.png",
      transforms: {
        caption: { x: 880, y: 840, width: 1140, height: 660, rotation: 0, zIndex: 4 },
        device: { x: 2180, y: 780, width: 500, height: 1019, rotation: 0, zIndex: 3 },
      },
    },
  ];
}

function tvStarter(): Slide[] {
  return [
    { id: nid(), layout: "hero", label: en("MEET YOUR APP"), headline: en("Made for\nthe living room."), screenshot: "" },
  ];
}

function watchStarter(): Slide[] {
  return [
    { id: nid(), layout: "hero", label: en("MEET YOUR APP"), headline: en("On your\nwrist."), screenshot: "" },
  ];
}

function carplayStarter(): Slide[] {
  return [
    { id: nid(), layout: "split-landscape", label: en("CARPLAY"), headline: en("Eyes on\nthe road."), screenshot: "" },
  ];
}

function tabletStarter(kind: "7" | "10"): Slide[] {
  return [
    {
      id: nid(),
      layout: "hero",
      label: en("MEET YOUR APP"),
      headline: en(kind === "7" ? "Pocket-sized\npower." : "Made for\nthe big screen."),
      screenshot: "",
    },
  ];
}

function macStarter(): Slide[] {
  return [
    { id: nid(), layout: "hero", label: en("MEET YOUR APP"), headline: en("Made for\nyour Mac."), screenshot: "" },
  ];
}

function duoOuterStarter(): Slide[] {
  return [
    { id: nid(), layout: "hero", label: en("MEET YOUR APP"), headline: en("Everything,\none hand."), screenshot: "" },
  ];
}

function duoOuterLandscapeStarter(): Slide[] {
  return [
    { id: nid(), layout: "hero", label: en("TURN IT"), headline: en("Made for the wide view."), screenshot: "" },
  ];
}

function duoInnerStarter(): Slide[] {
  return [
    { id: nid(), layout: "hero", label: en("UNFOLD IT"), headline: en("Room for\nthe whole view."), screenshot: "" },
  ];
}

function duoInnerLandscapeStarter(): Slide[] {
  return [
    { id: nid(), layout: "hero", label: en("UNFOLD IT"), headline: en("Lead with the two-pane view."), screenshot: "" },
  ];
}

function fgStarter(): Slide[] {
  return [
    {
      id: nid(),
      layout: "feature-graphic",
      label: {},
      headline: en("Color at your own pace."),
      screenshot: "",
    },
  ];
}

export const DEFAULT_PROJECT: ProjectState = {
  schemaVersion: PROJECT_SCHEMA_VERSION,
  appName: "Quiet Canvas",
  themeId: "quiet-japandi",
  fontId: "template-serif",
  connectedCanvas: true,
  locales: [DEFAULT_LOCALE],
  locale: DEFAULT_LOCALE,
  device: "iphone",
  orientation: "portrait",
  appIcon: "/app-icon.png",
  slidesByDevice: {
    iphone: iphoneQuietCanvas(),
    android: iphoneQuietCanvas(),
    ipad: ipadQuietCanvas(),
    tvos: tvStarter(),
    watchos: watchStarter(),
    carplay: carplayStarter(),
    mac: macStarter(),
    "android-7": tabletStarter("7"),
    "android-10": tabletStarter("10"),
    "feature-graphic": fgStarter(),
    "duo-outer": duoOuterStarter(),
    "duo-outer-landscape": duoOuterLandscapeStarter(),
    "duo-inner": duoInnerStarter(),
    "duo-inner-landscape": duoInnerLandscapeStarter(),
    "creative-universal": creativeUniversalQuietCanvas(),
    "creative-header": creativeHeaderQuietCanvas(),
    "creative-search": creativeSearchQuietCanvas(),
  },
};

export function newSlide(layout: Slide["layout"] = "device-bottom"): Slide {
  return {
    id: nid(),
    layout,
    label: en("NEW"),
    headline: en("Edit this\nheadline."),
    screenshot: "",
  };
}

export function detectPlatform(device: Device): Platform {
  const platforms = Object.keys(PLATFORM_DEVICES) as Platform[];
  return platforms.find((p) => PLATFORM_DEVICES[p].includes(device)) ?? "ios";
}

import type { Metadata } from "next";
import { Inter, Shippori_Mincho, Zen_Kaku_Gothic_New, Yuji_Syuku } from "next/font/google";
import "./globals.css";

const font = Inter({ subsets: ["latin"] });
const mincho = Shippori_Mincho({
  weight: ["400", "500", "600"],
  subsets: ["latin"],
  variable: "--font-mincho",
  display: "block",
  preload: false,
});
const kaku = Zen_Kaku_Gothic_New({
  weight: ["400", "500", "700"],
  subsets: ["latin"],
  variable: "--font-kaku",
  display: "block",
  preload: false,
});
const seal = Yuji_Syuku({
  weight: "400",
  subsets: ["latin"],
  variable: "--font-seal",
  display: "block",
  preload: false,
});

export const metadata: Metadata = {
  title: "Quiet Canvas — App Store Screenshots",
  description: "Design and export App Store + Google Play screenshots.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={`${font.className} ${mincho.variable} ${kaku.variable} ${seal.variable}`}>
        {children}
      </body>
    </html>
  );
}

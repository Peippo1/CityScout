import type { Metadata } from "next";
import { Fraunces, Manrope } from "next/font/google";
import type { ReactNode } from "react";
import "./globals.css";

const display = Fraunces({
  subsets: ["latin"],
  variable: "--font-display"
});

const sans = Manrope({
  subsets: ["latin"],
  variable: "--font-sans"
});

export const metadata: Metadata = {
  title: "CityScout Web",
  description: "CityScout planning surface for city days, itinerary drafting, and travel sharing."
};

export default function RootLayout({
  children
}: Readonly<{
  children: ReactNode;
}>) {
  return (
    <html lang="en" className={`${display.variable} ${sans.variable}`}>
      <body>{children}</body>
    </html>
  );
}

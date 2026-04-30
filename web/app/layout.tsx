import type { Metadata } from "next";
import { Baskervville, Inter } from "next/font/google";
import type { ReactNode } from "react";
import "./globals.css";

const editorial = Baskervville({
  subsets: ["latin"],
  variable: "--font-editorial",
  weight: ["400"]
});

const sans = Inter({
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
    <html lang="en" className={`${editorial.variable} ${sans.variable}`}>
      <body>{children}</body>
    </html>
  );
}

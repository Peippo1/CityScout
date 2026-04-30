/** @type {import('tailwindcss').Config} */
const config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./lib/**/*.{ts,tsx}", "./types/**/*.{ts,tsx}"],
  theme: {
    extend: {
      boxShadow: {
        glow: "0 0 0 1px rgba(255,255,255,0.08), 0 28px 80px rgba(0,0,0,0.45)"
      },
      colors: {
        city: {
          ink: "#060b19",
          navy: "#0b1328",
          slate: "#111a34",
          surface: "rgba(15, 23, 42, 0.72)",
          border: "rgba(255, 255, 255, 0.10)",
          text: "#f5f7fb",
          muted: "rgba(245, 247, 251, 0.68)",
          accent: "#88d6ff",
          accentSoft: "#d9f1ff",
          warm: "#f2b880"
        }
      }
    }
  },
  plugins: []
};

export default config;

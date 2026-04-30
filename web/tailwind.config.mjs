/** @type {import('tailwindcss').Config} */
const config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./lib/**/*.{ts,tsx}", "./types/**/*.{ts,tsx}"],
  theme: {
    extend: {
      boxShadow: {
        soft: "0 10px 24px rgba(17, 17, 17, 0.035)"
      },
      fontFamily: {
        sans: ["var(--font-sans)", "Inter", "system-ui", "sans-serif"],
        editorial: ["var(--font-editorial)", '"Iowan Old Style"', "Baskerville", "Georgia", "serif"]
      },
      colors: {
        city: {
          ink: "#111111",
          muted: "rgba(17, 17, 17, 0.66)",
          border: "rgba(17, 17, 17, 0.1)",
          surface: "rgba(255, 255, 255, 0.7)",
          background: "#f8f6f1"
        }
      }
    }
  },
  plugins: []
};

export default config;

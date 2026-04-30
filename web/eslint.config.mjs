import coreWebVitals from "eslint-config-next/core-web-vitals";
import nextTypeScript from "eslint-config-next/typescript";

const eslintConfig = [
  {
    ignores: [".next/**", "node_modules/**", "playwright-report/**"]
  },
  ...coreWebVitals,
  ...nextTypeScript
];

export default eslintConfig;

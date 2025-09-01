// Minimal flat ESLint config (JS only)
import js from "@eslint/js";

export default [
  js.configs.recommended,
  {
    files: ["**/*.mjs", "**/*.cjs", "**/*.js"],
    languageOptions: { ecmaVersion: 2022, sourceType: "module" },
    ignores: ["**/node_modules/**", ".git/**", "**/*.bak*", "**/*.tgz"],
    rules: {
      "no-console": "off",
      "no-unused-vars": ["warn", { argsIgnorePattern: "^_" }],
    },
  },
];


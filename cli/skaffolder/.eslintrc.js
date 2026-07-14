module.exports = {
  env: {
    es2022: true,
    node: true,
  },
  parser: "@typescript-eslint/parser",
  plugins: ["@typescript-eslint", "unicorn", "github"],
  extends: [
    "eslint:recommended",
    "plugin:github/recommended",
    "plugin:import/recommended",
    "plugin:import/typescript",
    "plugin:prettier/recommended",
    "plugin:@typescript-eslint/recommended",
  ],
  parserOptions: {
    ecmaVersion: 12,
    sourceType: "module",
    project: ["./tsconfig.json"],
  },
  ignorePatterns: [".eslintrc.js"],
  rules: {
    // github disables
    "i18n-text/no-en": "off",
    "filenames/match-regex": "off",
    "object-shorthand": "off",
    camelcase: "off",
    "no-shadow": "off",

    "no-console": "error",
    "require-await": "error",
    "@typescript-eslint/no-shadow": "error",
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-floating-promises": "error",
    "unicorn/no-abusive-eslint-disable": "error",
    "no-unused-vars": "off",
    "@typescript-eslint/explicit-module-boundary-types": "warn",
    "@typescript-eslint/no-unused-vars": [
      "error",
      {
        argsIgnorePattern: "^_",
        // "varsIgnorePattern": "^_",
        // "caughtErrorsIgnorePattern": "^_"
      },
    ],
    // "max-len": [
    //   "error",
    //   {
    //     code: 100,
    //     tabWidth: 2,
    //     ignoreUrls: true,
    //     ignorePattern: "(^import\\s.+\\sfrom\\s.+;$)|(private readonly\\s.+;$)",
    //     ignoreTemplateLiterals: true,
    //     ignoreRegExpLiterals: true,
    //     ignoreComments: true,
    //   },
    // ],
    quotes: ["off"],
    "prettier/prettier": ["error", { singleQuote: false }],
    curly: ["error", "all"],
    "brace-style": ["error", "1tbs", { allowSingleLine: false }],
  },
  settings: {
    "import/resolver": {
      typescript: {},
    },
  },
};

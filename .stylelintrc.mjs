export default {
  extends: ['stylelint-config-standard'],
  rules: {
    /*
     * Tailwind v4 configures itself in CSS rather than in a JavaScript config
     * file, so a stock stylelint sees its directives as unknown syntax. These
     * two rules are narrowed to the specific at-rules Tailwind defines rather
     * than switched off, so a genuine typo in any other at-rule is still caught.
     */
    'at-rule-no-unknown': [
      true,
      {
        ignoreAtRules: [
          'theme',
          'source',
          'utility',
          'variant',
          'custom-variant',
          'apply',
          'reference',
          'config',
          'plugin',
        ],
      },
    ],
    // `@import "tailwindcss"` is Tailwind's documented entry syntax; the
    // url() form the standard config prefers is not what its plugin looks for.
    'import-notation': null,
  },
};

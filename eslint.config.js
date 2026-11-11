export default [{
  files: ['**/*.js'],

  languageOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },

  rules: {
    'block-spacing': ['error', 'never'],
    'consistent-return': 'off',

    'keyword-spacing': [
      'error',
      {
        after: false,
        overrides: {
          case: { after: true },
          const: { after: true },
          do: { after: true },
          else: { after: true },
          from: { after: true },
          import: { after: true },
          return: { after: true },
          try: { after: true },
        }
      }
    ],

    'no-continue': 'off',
    'no-plusplus': 'off',
    'no-shadow': 'off',

    'no-unused-vars': [
      'error',
      {
        argsIgnorePattern: '^_',
        destructuredArrayIgnorePattern: '^_',
      },
    ],

    'no-use-before-define': ['error', { functions: false }],
    'no-param-reassign': 'off',
    'object-curly-spacing': ['error', 'never'],
    'space-infix-ops': 'off',
  },
}];

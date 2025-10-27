export default {
  plugins: {
    'postcss-preset-env': {
      stage: 1,
      features: {
        'nesting-rules': true,
        'custom-properties': true,
        'custom-media-queries': true,
        'media-query-ranges': true,
      },
    },
    tailwindcss: {},
    autoprefixer: {},
  },
};

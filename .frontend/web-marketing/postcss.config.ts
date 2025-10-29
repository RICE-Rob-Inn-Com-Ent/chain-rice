import tailwindcss from "tailwindcss";
import autoprefixer from "autoprefixer";
import postcssPresetEnv from "postcss-preset-env";

export default {
  plugins: [
    postcssPresetEnv({
      stage: 1,
      features: {
        "nesting-rules": true,
        "custom-properties": true,
      },
    }),
    tailwindcss(),
    autoprefixer(),
  ],
};


import { defineConfig } from 'vite';
import { extensions, classicEmberSupport, ember } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';

export default defineConfig({
  server: {
    port: 4200,
    // Ember can use same-origin /api URLs during development. Vite forwards
    // the requests to Rails, so there is no browser CORS setup to maintain.
    proxy: {
      '/api': 'http://127.0.0.1:3000',
    },
  },
  plugins: [
    classicEmberSupport(),
    ember(),
    // extra plugins here
    babel({
      babelHelpers: 'runtime',
      extensions,
    }),
  ],
});

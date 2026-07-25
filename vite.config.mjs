import { defineConfig } from 'vite';
import { extensions, classicEmberSupport, ember } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [
    classicEmberSupport(),
    ember(),
    // Tailwind v4 is a Vite plugin: it scans templates for class names and
    // fills in the `@import "tailwindcss"` in app/styles/app.css. There is no
    // PostCSS config and no tailwind.config.js; content sources and theme
    // customisation live in the CSS itself.
    tailwindcss(),
    babel({
      babelHelpers: 'runtime',
      extensions,
    }),
  ],

  server: {
    // Bound to an explicit IPv4 address rather than the default. On macOS
    // "localhost" resolves to ::1 first, and the development Caddyfile dials
    // 127.0.0.1, so leaving this to the default makes the proxy fail to
    // connect even though the dev server is running.
    host: '127.0.0.1',
    port: 4200,
    strictPort: true,

    // Development runs behind Caddy on http://localhost:8081 so the browser
    // sees a single origin, exactly as production does behind nginx. Requests
    // the app makes to /api/... need no proxy there: Caddy routes that prefix
    // to the Go API before Vite ever sees it.
    //
    // This proxy is the fallback for running Vite directly on :4200 without
    // Caddy. It keeps the app usable, but the API then sees a different origin,
    // so prefer the Caddy setup described in the README.
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:3000',
        changeOrigin: false,
      },
    },
  },
});

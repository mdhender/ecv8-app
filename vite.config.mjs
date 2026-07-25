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
    // "localhost" resolves to ::1 first, so a proxy that dials 127.0.0.1 fails
    // to connect even though the dev server is running. Pinning the bind here
    // makes the upstream address unambiguous whichever form the proxy uses.
    host: '127.0.0.1',
    port: 4200,
    strictPort: true,

    // Development runs behind Caddy on https://ecv8.localhost:8443 so the
    // browser sees a single origin over HTTPS, exactly as production does behind
    // nginx. Requests the app makes to /api/... need no proxy there: Caddy routes
    // that prefix to the Go API before Vite ever sees it.
    //
    // This proxy is only the fallback for running Vite directly on :4200 with no
    // proxy at all. It keeps the app loading, but the API then sees a different
    // origin, so the session cookie is not sent and nothing authenticates. Use
    // the Caddy setup described in the README.
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:3000',
        changeOrigin: false,
      },
    },
  },
});

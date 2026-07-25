# ec — ECV8 web client

The Ember application for **ECV8**, a turn-based 4X science-fiction game. It
provides sign-in, account activation, a player dashboard and profile, and the
administrative interface for accounts, games, and game memberships.

It talks to the Go API in the sibling `api/` repository. This repository is
independent: it is not a submodule of `api/`, and there is no parent repository
above the two.

---

## Contents

- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Commands](#commands)
- [Configuration](#configuration)
- [Architecture](#architecture)
  - [Authentication](#authentication)
  - [Routes](#routes)
  - [Styling](#styling)
- [Security notes](#security-notes)
- [Tests](#tests)

---

## Requirements

| Tool  | Version | Notes                                                 |
| ----- | ------- | ----------------------------------------------------- |
| Node  | ≥ 20.19 | Developed on 22.x.                                    |
| pnpm  | 11.x    | The lockfile is `pnpm-lock.yaml`; commit it.          |
| Caddy | 2.x     | Development proxy over HTTPS; see `../api/README.md`. |

Built on **Ember 7.1.0** — the latest stable release — with Embroider and Vite.
JavaScript, not TypeScript.

---

## Quick start

The application is developed behind a Caddy proxy so that it and the API share
one origin over HTTPS, exactly as they do in production behind nginx. A
long-running system Caddy serves `ecv8.localhost:8443` with `tls internal`; the
site block to add is in `../api/README.md` under Development.

With Caddy already running as a service, both processes start together from a
`Procfile.dev` in the directory above the two repositories:

```
backend: cd api && air
frontend: cd app && pnpm start
```

```bash
pnpm install
overmind start -f Procfile.dev     # or: foreman, hivemind, two terminals
```

Then browse **https://ecv8.localhost:8443**.

Do **not** browse `http://localhost:4200` directly. That bypasses the proxy, so
the API sees a different origin, the session cookie is not sent, and nothing
authenticates. Vite does carry a fallback `/api` proxy for that case, but the
Caddy setup is what matches production and is what you should use.

If you have no system Caddy, `../api/dev/Caddyfile` is a self-contained
alternative on plain HTTP at `http://localhost:8081`; see `../api/README.md`.

To work against a throwaway database rather than a real one, run the API with
`--memory dev`. That gives four accounts — `admin@example.com/admin`,
`gm1@example.com/gm1`, `user1@example.com/user1`, `user2@example.com/user2` —
discarded when it exits.

---

## Commands

| Command         | Purpose                                                      |
| --------------- | ------------------------------------------------------------ |
| `pnpm start`    | Dev server on `127.0.0.1:4200` with HMR.                     |
| `pnpm build`    | Production build into `dist/`.                               |
| `pnpm lint`     | ESLint, template lint, stylelint, and Prettier, in parallel. |
| `pnpm lint:fix` | Fix what is fixable, then format.                            |
| `pnpm format`   | Prettier only.                                               |

---

## Configuration

The API's location is configured in exactly one place: `apiPath` in
`config/environment.js`, which defaults to `/api/v1`.

It is a **root-relative path, never an absolute URL**. Production behind nginx
and development behind Caddy both serve this application and the API from one
origin, so a relative path is correct in both, and there is no production CORS to
configure. Point it elsewhere only if the API genuinely moves to another origin —
which would also require CORS on the server and `SameSite=None` cookies.

`config/environment.js` also sets Ember Simple Auth's `routeAfterAuthentication`.

---

## Architecture

```
app/
  app.js                     application; imports the Tailwind entry
  router.js                  route map
  tailwind.css               Tailwind entry point (see Styling)
  authenticators/cookie.js   Ember Simple Auth authenticator
  session-stores/            server-backed session store
  services/
    api.js                   the only place that talks to the API
    session.js               session service plus redirect safety
    activation-links.js      holds the most recent magic link
  routes/                    route classes, model loading, guards
  controllers/               query-parameter declarations only
  templates/                 .gjs route templates
  components/                .gjs components
  utils/
    routes.js                ProtectedRoute and AdminRoute base classes
    format.js                date formatting
```

Everything is strict-mode `.gjs`. There are no `.hbs` files, no classic
components, no mixins, and no observers.

**Controllers exist only where Ember requires them.** A route's `queryParams`
hash configures behaviour such as `refreshModel`, but the query-parameter binding
itself must still be declared on a controller. The three controllers here do
nothing else.

**The API service** (`services/api.js`) centralises the base path, the JSON
headers, `credentials: 'same-origin'`, and error handling. It parses the API's
RFC 9457 Problem Details into an `ApiError` carrying `status` and a `fields` map
of per-field messages, so forms render inline validation without each one
re-implementing the parsing.

### Authentication

Ember Simple Auth 8.3.1, wired to **server-side cookie sessions**. There is no
token anywhere in the client.

- `authenticators/cookie.js` posts credentials to `/session`. The server replies
  with an `HttpOnly` cookie the browser stores and JavaScript cannot read.
- `session-stores/application.js` is a custom `BaseStore` whose `restore()` calls
  `GET /session`. **The server is the session store.** Nothing is persisted in
  `localStorage`, in a script-readable cookie, or in memory — on page load the
  application simply asks the API who the cookie belongs to.
- `services/session.js` extends Ember Simple Auth's session service with
  `account`, `isAdmin`, `isImpersonating`, and `impersonator`, plus a `refresh()`
  that re-reads the session after impersonation starts or stops.

Two consequences worth knowing:

- **Cross-tab sign-out is not instant.** There is no storage event to listen for,
  because nothing is in storage. A second tab notices on its next navigation or
  reload, when `restore()` runs again.
- **Session data cannot be patched locally.** `authenticated` is a key Ember
  Simple Auth reserves for authenticators. Anything that changes the session
  server-side is therefore followed by `session.refresh()`, which re-reads
  `/session` — so the client shows what the server actually thinks rather than a
  local guess.

### Routes

| Route                 | Guard          | Purpose                                                       |
| --------------------- | -------------- | ------------------------------------------------------------- |
| `/login`              | anonymous only | Sign in.                                                      |
| `/activate?token=…`   | none           | Redeem a magic link and set the first password.               |
| `/dashboard`          | authenticated  | The player's games.                                           |
| `/games`              | authenticated  | The games you are seated at.                                  |
| `/games/:id`          | authenticated  | One game: its state, or its game master's setup form.         |
| `/profile`            | authenticated  | Display name, time zone, password.                            |
| `/admin`              | administrator  | Section shell; redirects to accounts.                         |
| `/admin/accounts`     | administrator  | List, filter, invite.                                         |
| `/admin/accounts/:id` | administrator  | Edit, deactivate, reissue link, revoke sessions, impersonate. |
| `/admin/games`        | administrator  | List, filter, create.                                         |
| `/admin/games/:id`    | administrator  | Rename, deactivate, manage memberships.                       |

Each list route has an `index` child so the parent can host the detail route's
outlet. `ProtectedRoute` and `AdminRoute` in `utils/routes.js` are the guards.

**Route guards are not a security boundary.** They keep an anonymous visitor from
seeing an empty page and keep admin links out of a normal user's way. Every
request is authorised independently by the server, so a user who defeats a guard
still gets `401` or `403`.

An administrator who is impersonating counts as a non-administrator here,
matching the server, which refuses `/admin/*` for the duration.

**`/games/:id` has no game-master guard, and should not grow one.** Whether you
may see a game, and whether you may set one up, follow from the seat you hold at
it — which the server resolves per request from `game_player`. The page renders
what the server says: `is_gm` decides whether the setup form or the "being set
up" message appears, and a game you have no seat at is a `404` the error route
renders. An administrator holds no seat, so `/games/:id` is a `404` for one; the
way to see a player's game is to impersonate them.

**Redirects are validated.** Ember Simple Auth records the page an anonymous
visitor asked for and returns them to it after signing in. That destination comes
back out of `sessionStorage`, so it is treated as untrusted: `safeRedirectPath`
in `services/session.js` accepts only a root-relative path and rejects
protocol-relative (`//host`), absolute (`https://host`), and backslash-prefixed
forms, so a poisoned value cannot bounce a freshly signed-in user off-site.

### Styling

Tailwind CSS v4 through `@tailwindcss/vite`. There is no `tailwind.config.js` and
no PostCSS config; the theme lives in `app/tailwind.css`.

That file is **not** under `app/styles/`, and the placement matters. Embroider's
classic pipeline concatenates everything in `app/styles/` into a virtual
`app.css` that Vite never processes, so a Tailwind directive placed there would
ship to the browser verbatim and generate no utilities. Importing
`app/tailwind.css` from `app/app.js` routes it through Vite instead, where the
Tailwind plugin runs.

Tailwind also does not scan `.gjs` by default, so `app/tailwind.css` registers
the app tree with `@source`. Without that, utilities used inside `<template>`
blocks are dropped from the production build.

`.stylelintrc.mjs` teaches stylelint about Tailwind's at-rules (`@theme`,
`@source`, and friends) by naming them explicitly, so a genuine typo in any other
at-rule is still caught.

The interface is responsive, supports light and dark colour schemes, and uses
semantic forms with labels, `aria-describedby` validation messages, a skip link,
and a visible focus ring.

---

## Security notes

- **No authentication state or bearer secret in `localStorage`.** The credential
  is an `HttpOnly` cookie; the client never holds a token.
- **Credentials are sent** with `credentials: 'same-origin'` on every request.
- **Admin navigation is hidden** from non-administrators, but that is presentation
  only — the server authorises.
- **Impersonation is unmistakable.** A persistent banner names both the
  impersonated account and the real administrator, and offers a one-click exit.
  While impersonating, the admin section is inaccessible and passwords cannot be
  changed.
- **Magic links are shown once.** The API returns an activation URL a single
  time, because only its hash is stored and the application does not send email.
  The link is held in the `activation-links` service rather than in the form that
  created it, so the route refresh that picks up the new account cannot destroy
  it before the administrator copies it. Losing it means reissuing.
- **Redirect destinations are validated** before use; see above.

---

## Tests

There are none yet. No unit, rendering, or acceptance tests exist, and no
harness is installed — the generated scaffolding (`tests/`, `testem.cjs`, QUnit,
and the `test` script) was removed rather than kept as meaningless green checks,
so `pnpm lint` and `pnpm build` are the checks that run. Tests are welcome;
adding the first one means reinstating a harness, and this section is the place
to record what it covers.

---

## Further reading

- [Ember guides](https://guides.emberjs.com/release/)
- [Ember Simple Auth](https://github.com/mainmatter/ember-simple-auth)
- [Embroider and Vite](https://github.com/embroider-build/embroider)
- [Tailwind CSS](https://tailwindcss.com/docs)

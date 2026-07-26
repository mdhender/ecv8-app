# CLAUDE.md — working in `app/`

The Ember client for ECV8. `README.md` in this directory explains _what_ the
application is and how it is put together; read it before changing anything
structural. This file is the shorter list of _how to work here_ — the
conventions, the checks, and the traps.

## Orientation

| Question                      | Where the answer is             |
| ----------------------------- | ------------------------------- |
| What the app does, why        | `README.md` (this directory)    |
| API endpoints, request shapes | `../api/README.md` § HTTP API   |
| Ember MCP server setup        | `EMBER-MCP.md` (this directory) |
| Original brief                | `../project-prompt.txt`         |
| Rules for the API side        | `../api/CLAUDE.md`              |

This directory is its own git repository. `../api` is a separate one, and there
is no parent repository above them — do not stage or commit across the two.

## Use the Ember MCP server

An `ember` MCP server is registered in this directory's `.mcp.json` for a
reason: **do not write Ember code from recall.** Trained-in defaults skew toward
classic Ember (`.hbs` files, `inject as service`, `@action`, controllers doing
work), and none of that belongs in this codebase. Before writing components,
templates, routers, or anything else Ember-shaped, look up the current idiom
with `search_ember_docs` / `get_api_reference` / `get_best_practices`.

Setup, refresh, and troubleshooting for that server: `EMBER-MCP.md`.

## Commands

Run everything from this directory. **pnpm only** — never npm or yarn; the
lockfile is `pnpm-lock.yaml` and it is committed.

**pnpm settings live in `pnpm-workspace.yaml`, not in `package.json`.** pnpm 11
stopped reading the `pnpm` field, and it does not fail — it prints one warning
and carries on with the setting ignored, so a change made there looks like it
worked. There is no workspace here; the file exists because that is where the
`overrides` entry pinning a patched `tmp` has to go. It documents its own reasons,
and `pnpm install` after touching it is what proves the override still resolves.

```bash
pnpm lint        # eslint + ember-template-lint + stylelint + prettier --check
pnpm lint:fix    # fix what is fixable, then format
pnpm build       # production build into dist/
pnpm start       # dev server on 127.0.0.1:4200
```

**Tests are welcome.** Add them where they earn their keep, without asking
first. There are none today and no harness is installed: the generated
scaffolding — `tests/`, `testem.cjs`, QUnit, and the `test` script — was removed
because it asserted nothing, not because tests are unwanted. Placeholders and
tests that assert nothing are still off the table. Adding the first real test
means reinstating a harness on purpose, so look up the current Ember idiom with
the MCP server rather than recalling one, and record what is covered in
`README.md` § Tests in the same change.

`pnpm lint && pnpm build` are the checks. Run both after any change and report
the real output.

`pnpm lint` fails on formatting, and Prettier formats inside `<template>` blocks
via `prettier-plugin-ember-template-tag`. Finish edits with `pnpm lint:fix`
rather than hand-aligning markup.

**Ember 7.1.0, Node ≥ 20.19, pnpm 11.x** are what this is built on;
`ember-source` and `ember-cli` are pinned at `~7.1.0`. If the local toolchain
disagrees, stop and report it rather than bumping a pin, editing `engines`, or
switching package managers to make an install succeed.

To see a change in a browser, use the Caddy setup at
**https://ecv8.localhost:8443** (`README.md` § Quick start). Loading
`http://localhost:4200` directly bypasses the proxy, so the session cookie is
never sent and nothing authenticates — anything touching auth will look broken
for reasons that have nothing to do with your change.

## Conventions this codebase already follows

Match them; do not introduce a second style alongside them.

- **JavaScript, not TypeScript.** No `.ts`/`.gts`.
- **Strict-mode `.gjs` everywhere.** No `.hbs` files, no classic components, no
  mixins, no observers, no `ember-data`. Templates and components import what
  they use.
- `import Component from '@glimmer/component'`, `@tracked` for state,
  `import { service } from '@ember/service'` (never `inject as service`),
  `import { on } from '@ember/modifier'` for events.
- **Event handlers are arrow-function class properties**, not `@action`
  methods — see `app/components/login-form.gjs`.
- **Absolute module paths under the `ec` prefix** — `modulePrefix` is `ec`, so
  it is `import Field from 'ec/components/ui/field'`, never a relative path.
- Route templates receive `@model` and `@controller`. Pure display helpers can
  be plain module-scope functions in the `.gjs` file (see
  `app/templates/admin/accounts/index.gjs`).
- **API payloads stay snake_case** — `display_name`, `is_active`,
  `active_sessions`, `is_admin`. Do not camelCase them on the way in; templates
  read the server's field names directly.
- Every source file carries a block comment explaining _why_ it exists, not what
  it does. New files should too.

## Rules with teeth

**All HTTP goes through `services/api.js`.** It is the only `fetch` in the app
and owns the base path, JSON headers, `credentials: 'same-origin'`, and error
parsing. Add a method there rather than fetching from a route or component.

**Failures are `ApiError`.** It parses RFC 9457 Problem Details into `status`,
`title`, `detail`, and a `fields` map for inline validation, plus
`isUnauthorized` / `isForbidden` / `isGone` / `isValidation`. Forms render
`error.fields[name]` through the `Ui::Field` component; they do not re-parse
problem documents.

**Never store authentication state on the client.** The credential is an
`HttpOnly` cookie; `session-stores/application.js` answers `restore()` by
asking `GET /session`. No `localStorage`, no readable cookie, no in-memory
copy.

**Never assign `session.data.authenticated`** — Ember Simple Auth reserves that
key for authenticators. After anything that changes the session server-side
(impersonation start/stop, editing your own profile), call
`session.refresh()`, which re-reads `/session`.

**Route guards are UX, not security.** Extend `ProtectedRoute` or `AdminRoute`
from `app/utils/routes.js`. Never treat a guard as authorisation, and never add
a client-side check as a substitute for one on the server — the API authorises
every request independently. The same applies to navigation: admin links stay
hidden from non-administrators, and an impersonating administrator counts as a
non-administrator, but that is presentation only — hiding a link protects
nothing.

**Redirect targets are untrusted.** The post-login destination comes out of
`sessionStorage`; anything consuming it goes through `safeRedirectPath` in
`services/session.js`.

**`apiPath` in `config/environment.js` is the one place the API's location
lives**, and it is root-relative (`/api/v1`). Do not hardcode a path elsewhere
and do not turn it into an absolute URL — that would require server CORS and
`SameSite=None` cookies.

**Controllers exist only to declare query parameters.** If you add a filter to a
list route, update both the route's `queryParams` hash (with `refreshModel:
true`) and the controller's `queryParams` array plus its default value. Filtering
must happen server-side; filtering in the browser would only filter the current
page.

## Styling

Tailwind CSS v4 via `@tailwindcss/vite`. There is **no `tailwind.config.js` and
no PostCSS config** — the theme is `@theme` in `app/tailwind.css`.

- **Do not put Tailwind directives in `app/styles/`.** Embroider concatenates
  that directory into a virtual `app.css` that Vite never processes, so the
  directive would ship verbatim and generate nothing. `app/tailwind.css` is
  imported from `app/app.js` so Vite handles it.
- If you add source outside the scanned tree, add an `@source` line — Tailwind
  does not scan `.gjs` by default, and unregistered classes vanish from the
  production build.
- Brand colours are `brand-50` … `brand-900`; use them rather than new hexes.
- **Every colour needs a `dark:` counterpart.** Light and dark are both
  supported and reviewed.
- Accessibility is not optional here: labelled controls (use `Ui::Field`, which
  wires `for`/`id`, `aria-describedby`, and `aria-invalid`), `scope` on table
  headers, `sr-only` captions, the skip link, a useful page title on every route
  (`ember-page-title`), and the global `:focus-visible` ring left intact.

## Adding a route — the whole checklist

1. `app/router.js` — add it (detail routes nest so they have their own URL).
2. `app/routes/<name>.js` — extend `ProtectedRoute` or `AdminRoute`; load data
   via `this.api`.
3. `app/controllers/<name>.js` — **only** if it has query parameters.
4. `app/templates/<name>.gjs` — the template, importing its components, opening
   with `{{pageTitle "…"}}`.
5. `app/components/…` — shared pieces go under `ui/`, admin-only under `admin/`.
6. Cover the states, not just the happy path: loading, empty, inline validation,
   expired or already-redeemed link, unauthorised, and server error. A route
   that renders only its success case is not finished.
7. `pnpm lint:fix && pnpm lint && pnpm build`.
8. Update the route table in `README.md`.

## Local development accounts

Running the API with `--memory dev` gives four throwaway accounts:
`admin@example.com/admin`, `gm1@example.com/gm1`, `user1@example.com/user1`,
`user2@example.com/user2`.

## Out of scope

The brief rules these out, and "no" is the finished answer, not a gap to fill:

- CI configuration, Dockerfiles, Docker Compose, deployment automation
- nginx configuration — production is an operator concern; `../api/dev/Caddyfile`
  and the system Caddy site block are the only proxy config in the projects
- **public web-based registration.** There is no sign-up route, and `/login`
  must not grow a "create an account" link. Administrators invite every account,
  and the invitee arrives through `/activate?token=…`.
- email delivery: nothing here sends mail. The activation URL is displayed once
  for the administrator to deliver out of band, which is why
  `services/activation-links.js` holds it across the route refresh.
- elaborate branding or visual redesign. Responsive, accessible, light and dark
  — that is the bar, and it is already met.

**A game interface is no longer on this list.** It used to say "`/dashboard`
lists memberships; gameplay is not built", and that has been superseded:
`/games` and `/games/:id` exist, and a game master sets a game up from the
latter. The API side made the same move — see `../api/CLAUDE.md` § The two
domains. Do not reinstate the old line from the brief or from an older comment.

**Nothing under `/games` guards on being a game master.** The seat decides, the
server owns the seat, and the page renders what it is told: `is_gm` chooses
between the setup form and the "being set up" message. Adding a client-side
check would be a second authority on a question that already has one, and it
would be the wrong one — see `README.md` § Routes.

**Do not add speculative abstractions for any of these** — no route, no service,
no config key held open for a feature that is not being built. If a change seems
to need one, say so and stop rather than building the scaffolding.

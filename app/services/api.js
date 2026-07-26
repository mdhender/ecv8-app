import Service, { service } from '@ember/service';
import config from 'ec/config/environment';

/**
 * ApiError carries a parsed RFC 9457 Problem Details document.
 *
 * The API answers every failure with `application/problem+json`, so one error
 * type covers every endpoint. `fields` holds the per-field validation messages
 * from the document's `errors` extension member, keyed by field name, ready for
 * a form to render inline.
 */
export class ApiError extends Error {
  constructor(problem, status) {
    super(problem?.detail || problem?.title || `Request failed (${status})`);
    this.name = 'ApiError';
    this.status = status;
    this.title = problem?.title ?? '';
    this.detail = problem?.detail ?? '';
    this.fields = Object.fromEntries(
      (problem?.errors ?? []).map((error) => [error.field, error.message]),
    );
  }

  /** True when the server rejected the request because no session is present. */
  get isUnauthorized() {
    return this.status === 401;
  }

  /** True when the session is valid but lacks permission. */
  get isForbidden() {
    return this.status === 403;
  }

  /** True when a magic link has been used or has expired. */
  get isGone() {
    return this.status === 410;
  }

  /** True when the request was well-formed but the server refused it. */
  get isValidation() {
    return this.status === 409 || this.status === 422;
  }
}

/**
 * ApiService is the only place the app talks to the API.
 *
 * Centralising it means the credentials mode, the JSON headers, and the error
 * shape are decided once. Every request sends the session cookie; because the
 * cookie is HttpOnly, no token is ever read or held by JavaScript.
 */
export default class ApiService extends Service {
  @service session;

  /** Root-relative base path of the versioned API. */
  get base() {
    return config.apiPath;
  }

  /**
   * Tells the session service when the server has answered "no session".
   *
   * This is the only place that learns of a session ending mid-visit, because
   * it is the only place that talks to the API. Leaving each caller to notice
   * would mean every route and form deciding for itself what a 401 implies, and
   * the ones that forgot would leave the client convinced it was still signed
   * in — see `expire` in the session service for what that looks like.
   *
   * `/session` is exempt. Its 401 is the expected answer for a signed-out
   * visitor and is already handled where it lands: the store reads it as "no
   * session" on page load, the authenticator as "already revoked" on sign-out.
   * Reacting here would only ask the same question a second time, and would
   * recurse, since asking is itself a `GET /session`.
   */
  async noteResponseStatus(path, status) {
    if (status === 401 && path !== '/session') {
      await this.session.expire();
    }
  }

  /**
   * Performs a request and returns the parsed `data` member.
   *
   * Rejects with an ApiError on any non-2xx status so callers can branch on
   * `status` instead of inspecting a response object.
   */
  async request(path, { method = 'GET', body, query } = {}) {
    let url = `${this.base}${path}`;
    if (query) {
      const params = new URLSearchParams();
      for (const [key, value] of Object.entries(query)) {
        if (value !== undefined && value !== null && value !== '') {
          params.set(key, value);
        }
      }
      const search = params.toString();
      if (search) {
        url += `?${search}`;
      }
    }

    const headers = { Accept: 'application/json' };
    if (body !== undefined) {
      headers['Content-Type'] = 'application/json';
    }

    const response = await fetch(url, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
      // The session cookie is same-origin. 'same-origin' is the default for
      // fetch, but stating it makes the dependency explicit and keeps the
      // request working if a caller ever moves this code.
      credentials: 'same-origin',
    });

    if (response.status === 204) {
      return null;
    }

    const text = await response.text();
    let payload = null;
    if (text) {
      try {
        payload = JSON.parse(text);
      } catch {
        payload = null;
      }
    }

    if (!response.ok) {
      await this.noteResponseStatus(path, response.status);
      throw new ApiError(payload, response.status);
    }
    return payload?.data ?? null;
  }

  /** Performs a request and returns both the `data` and `meta` members. */
  async requestWithMeta(path, options) {
    const url = `${this.base}${path}`;
    const params = new URLSearchParams();
    for (const [key, value] of Object.entries(options?.query ?? {})) {
      if (value !== undefined && value !== null && value !== '') {
        params.set(key, value);
      }
    }
    const search = params.toString();

    const response = await fetch(search ? `${url}?${search}` : url, {
      headers: { Accept: 'application/json' },
      credentials: 'same-origin',
    });

    const text = await response.text();
    const payload = text ? JSON.parse(text) : null;
    if (!response.ok) {
      await this.noteResponseStatus(path, response.status);
      throw new ApiError(payload, response.status);
    }
    return { data: payload?.data ?? [], meta: payload?.meta ?? null };
  }

  get(path, options) {
    return this.request(path, { ...options, method: 'GET' });
  }

  post(path, body) {
    return this.request(path, { method: 'POST', body });
  }

  patch(path, body) {
    return this.request(path, { method: 'PATCH', body });
  }

  put(path, body) {
    return this.request(path, { method: 'PUT', body });
  }

  delete(path) {
    return this.request(path, { method: 'DELETE' });
  }
}

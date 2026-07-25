import Component from '@glimmer/component';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import Alert from 'ec/components/ui/alert';
import Field from 'ec/components/ui/field';
import Badge from 'ec/components/ui/badge';
import { ApiError } from 'ec/services/api';

/** True when `current` matches `value`, for marking a <select> option. */
function isSelected(current, value) {
  return current === value;
}

/**
 * AccountForm is the administrator's view of a single account.
 *
 * It covers editing, deactivation, reissuing an activation link, revoking
 * sessions, and starting impersonation. Deactivation and session revocation are
 * kept as separate controls because they do separate things: deactivating
 * blocks future sign-ins but leaves current sessions alone, and revoking ends
 * current sessions without changing whether the account may sign in again.
 */
export default class AccountForm extends Component {
  @service api;
  @service router;
  @service session;
  @service activationLinks;

  // Each field starts as undefined and reads through to the loaded account
  // until the user edits it, so the refresh after a successful save shows the
  // server's version rather than stale local state.
  @tracked emailEdit;
  @tracked displayNameEdit;
  @tracked timezoneEdit;
  @tracked adminNotesEdit;
  @tracked roleEdit;

  get email() {
    return this.emailEdit ?? this.args.account.email;
  }

  get displayName() {
    return this.displayNameEdit ?? this.args.account.display_name;
  }

  get timezone() {
    return this.timezoneEdit ?? this.args.account.timezone;
  }

  get adminNotes() {
    return this.adminNotesEdit ?? this.args.account.admin_notes;
  }

  get role() {
    return this.roleEdit ?? this.args.account.role;
  }

  @tracked status = null;
  @tracked error = null;
  @tracked fieldErrors = {};
  @tracked busy = null;

  /** True while the save button specifically is the action in flight. */
  get isSaving() {
    return this.busy === 'save';
  }

  get account() {
    return this.args.account;
  }

  /**
   * Impersonation is offered only for an activated, active user account.
   * The server refuses every other case, so showing the button would only
   * produce an error message.
   */
  get canImpersonate() {
    return (
      this.account.role === 'user' &&
      this.account.is_active &&
      this.account.activated
    );
  }

  updateEmail = (event) => {
    this.emailEdit = event.target.value;
  };

  updateDisplayName = (event) => {
    this.displayNameEdit = event.target.value;
  };

  updateTimezone = (event) => {
    this.timezoneEdit = event.target.value;
  };

  updateNotes = (event) => {
    this.adminNotesEdit = event.target.value;
  };

  updateRole = (event) => {
    this.roleEdit = event.target.value;
  };

  /**
   * Runs one API call, funnelling every outcome into the banners above.
   *
   * `refresh` is opt-out because impersonation must not reload this route: the
   * moment the server accepts it, the session is acting as a user and this
   * admin-only endpoint would answer 403.
   */
  async perform(name, work, successMessage, { refresh = true } = {}) {
    this.status = null;
    this.error = null;
    this.fieldErrors = {};
    this.busy = name;
    try {
      const result = await work();
      if (successMessage) {
        this.status = successMessage;
      }
      if (refresh) {
        // Refresh only this route so the parent admin route, which renders the
        // activation-link banner, is left standing.
        this.router.refresh('admin.accounts.detail');
      }
      return result;
    } catch (error) {
      if (error instanceof ApiError) {
        this.error = error.message;
        this.fieldErrors = error.fields;
      } else {
        this.error = 'Could not reach the server. Try again.';
      }
      return null;
    } finally {
      this.busy = null;
    }
  }

  save = (event) => {
    event.preventDefault();
    return this.perform(
      'save',
      () =>
        this.api.patch(`/admin/accounts/${this.account.id}`, {
          email: this.email,
          display_name: this.displayName,
          timezone: this.timezone,
          admin_notes: this.adminNotes,
          role: this.role,
        }),
      'Account saved.',
    );
  };

  toggleActive = () => {
    const next = !this.account.is_active;
    return this.perform(
      'active',
      () =>
        this.api.patch(`/admin/accounts/${this.account.id}`, {
          is_active: next,
        }),
      next ? 'Account reactivated.' : 'Account deactivated.',
    );
  };

  reissue = async () => {
    const link = await this.perform('reissue', () =>
      this.api.post(`/admin/accounts/${this.account.id}/activation-link`, {}),
    );
    if (link) {
      this.activationLinks.remember(link);
    }
  };

  revokeSessions = () =>
    this.perform(
      'revoke',
      () => this.api.delete(`/admin/accounts/${this.account.id}/sessions`),
      'Sessions revoked.',
    );

  impersonate = async () => {
    const session = await this.perform(
      'impersonate',
      () =>
        this.api.post('/session/impersonation', {
          account_id: this.account.id,
        }),
      null,
      { refresh: false },
    );
    if (session) {
      // Re-read the session before navigating, so the navigation bar and the
      // impersonation banner reflect the new identity on arrival.
      await this.session.refresh();
      this.router.transitionTo('dashboard');
    }
  };

  <template>
    <div class="space-y-6">
      {{#if this.status}}
        <Alert @kind="success"><p>{{this.status}}</p></Alert>
      {{/if}}
      {{#if this.error}}
        <Alert @kind="error" @title="Could not complete that">
          <p>{{this.error}}</p>
        </Alert>
      {{/if}}
      <div class="flex flex-wrap items-center gap-2">
        <Badge @tone={{if this.account.is_active "on" "off"}}>
          {{if this.account.is_active "Active" "Deactivated"}}
        </Badge>
        <Badge @tone={{if this.account.activated "on" "warn"}}>
          {{if this.account.activated "Activated" "Never activated"}}
        </Badge>
        <Badge @tone="info">{{this.account.role}}</Badge>
        {{#if this.account.activation_pending}}
          <Badge @tone="warn">Activation link outstanding</Badge>
        {{/if}}
        <Badge @tone={{if this.account.active_sessions "on" "off"}}>
          {{this.account.active_sessions}}
          active sessions
        </Badge>
      </div>

      <form class="grid gap-4 sm:grid-cols-2" {{on "submit" this.save}}>
        <Field
          @name="account-email"
          @label="Email"
          @required={{true}}
          @error={{this.fieldErrors.email}}
          as |f|
        >
          <input
            id={{f.id}}
            type="email"
            required
            aria-invalid={{f.invalid}}
            aria-describedby={{f.describedBy}}
            value={{this.email}}
            class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "input" this.updateEmail}}
          />
        </Field>

        <Field
          @name="account-display-name"
          @label="Display name"
          @required={{true}}
          @error={{this.fieldErrors.display_name}}
          as |f|
        >
          <input
            id={{f.id}}
            type="text"
            required
            maxlength="100"
            aria-invalid={{f.invalid}}
            aria-describedby={{f.describedBy}}
            value={{this.displayName}}
            class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "input" this.updateDisplayName}}
          />
        </Field>

        <Field
          @name="account-timezone"
          @label="Time zone"
          @error={{this.fieldErrors.timezone}}
          as |f|
        >
          <input
            id={{f.id}}
            type="text"
            aria-invalid={{f.invalid}}
            aria-describedby={{f.describedBy}}
            value={{this.timezone}}
            class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "input" this.updateTimezone}}
          />
        </Field>

        <Field
          @name="account-role"
          @label="Role"
          @hint="Promoting a member of a game to administrator is refused."
          @error={{this.fieldErrors.role}}
          as |f|
        >
          <select
            id={{f.id}}
            aria-describedby={{f.describedBy}}
            class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "change" this.updateRole}}
          >
            <option value="user" selected={{isSelected this.role "user"}}>
              User
            </option>
            <option value="admin" selected={{isSelected this.role "admin"}}>
              Administrator
            </option>
          </select>
        </Field>

        <Field
          @name="account-notes"
          @label="Administrator notes"
          @hint="Visible to administrators only."
          as |f|
        >
          <textarea
            id={{f.id}}
            rows="3"
            class="w-full rounded-md border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            {{on "input" this.updateNotes}}
          >{{@account.admin_notes}}</textarea>
        </Field>

        <div class="flex items-end sm:col-span-2">
          <button
            type="submit"
            disabled={{this.busy}}
            class="rounded-md bg-brand-600 px-4 py-2 font-medium text-white hover:bg-brand-700 disabled:opacity-60"
          >
            {{if this.isSaving "Saving…" "Save changes"}}
          </button>
        </div>
      </form>

      <section
        class="space-y-3 rounded-md border border-slate-200 p-4 dark:border-slate-700"
      >
        <h3 class="text-lg font-semibold">Actions</h3>

        <div class="flex flex-wrap gap-2">
          <button
            type="button"
            disabled={{this.busy}}
            class="rounded-md border border-slate-300 px-3 py-2 text-sm hover:bg-slate-100 disabled:opacity-60 dark:border-slate-600 dark:hover:bg-slate-700"
            {{on "click" this.toggleActive}}
          >
            {{if
              this.account.is_active
              "Deactivate account"
              "Reactivate account"
            }}
          </button>

          <button
            type="button"
            disabled={{this.busy}}
            class="rounded-md border border-slate-300 px-3 py-2 text-sm hover:bg-slate-100 disabled:opacity-60 dark:border-slate-600 dark:hover:bg-slate-700"
            {{on "click" this.reissue}}
          >
            Reissue activation link
          </button>

          <button
            type="button"
            disabled={{this.busy}}
            class="rounded-md border border-slate-300 px-3 py-2 text-sm hover:bg-slate-100 disabled:opacity-60 dark:border-slate-600 dark:hover:bg-slate-700"
            {{on "click" this.revokeSessions}}
          >
            Revoke all sessions
          </button>

          {{#if this.canImpersonate}}
            <button
              type="button"
              disabled={{this.busy}}
              class="rounded-md border border-amber-400 px-3 py-2 text-sm text-amber-900 hover:bg-amber-50 disabled:opacity-60 dark:text-amber-100 dark:hover:bg-amber-900"
              {{on "click" this.impersonate}}
            >
              Impersonate
            </button>
          {{/if}}
        </div>

        <p class="text-sm text-slate-600 dark:text-slate-300">
          Deactivating blocks new sign-ins but leaves existing sessions running.
          Revoke sessions separately to sign this account out everywhere.
          Reissuing an activation link invalidates any link sent earlier.
        </p>
      </section>
    </div>
  </template>
}
